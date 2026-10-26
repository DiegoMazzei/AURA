import 'dart:async';

import 'package:flutter/material.dart';

import '../../app/aura_controller.dart';
import '../../core/design/aura_design.dart';
import 'online_track.dart';
import 'online_player_screen.dart';

class OnlineSearchScreen extends StatefulWidget {
  const OnlineSearchScreen({
    super.key,
    required this.controller,
    required this.onLocal,
    this.initialQuery = '',
    this.showLocalLink = true,
  });
  final AuraController controller;
  final VoidCallback onLocal;
  final String initialQuery;
  final bool showLocalLink;
  @override
  State<OnlineSearchScreen> createState() => _OnlineSearchScreenState();
}

class _OnlineSearchScreenState extends State<OnlineSearchScreen> {
  final _field = TextEditingController();
  Timer? _debounce;
  int _revision = 0;
  bool _loading = false;
  String? _error;
  List<OnlineTrack> _results = [];
  void _changed(String query) {
    _debounce?.cancel();
    ++_revision;
    if (query.trim().isEmpty) {
      setState(() {
        _results = [];
        _loading = false;
        _error = null;
      });
      return;
    }
    setState(() => _loading = true);
    _debounce = Timer(const Duration(milliseconds: 450), _search);
  }

  Future<void> _search() async {
    final id = youtubeVideoId(_field.text);
    if (id != null) {
      await openOnlinePlayer(
        context,
        widget.controller,
        OnlineTrack(id: id, title: 'Video YouTube', artist: 'YouTube'),
      );
      return;
    }
    final revision = ++_revision;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final results = await widget.controller.catalog.search(_field.text);
      if (!mounted || revision != _revision) return;
      setState(() {
        _results = results;
        _loading = false;
      });
    } catch (_) {
      if (!mounted || revision != _revision) return;
      setState(() {
        _loading = false;
        _error = 'YouTube non risponde al momento. Controlla la connessione e riprova.';
      });
    }
  }

  @override
  void initState() {
    super.initState();
    if (widget.initialQuery.isNotEmpty) {
      _field.text = widget.initialQuery;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _search();
      });
    }
  }

  @override
  void dispose() {
    _revision++;
    _debounce?.cancel();
    _field.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => ListView(
    padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
    children: [
      const Text(
        'Cerca',
        style: TextStyle(
          fontSize: 32,
          fontWeight: FontWeight.w600,
          letterSpacing: -1,
        ),
      ),
      const SizedBox(height: 15),
      Wrap(
        alignment: WrapAlignment.spaceBetween,
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: 12,
        children: [
          const Chip(
            label: Text('YouTube'),
            avatar: Icon(Icons.play_circle_outline, size: 18),
          ),
          if (widget.showLocalLink)
            TextButton(
              onPressed: widget.onLocal,
              child: const Text('Sul dispositivo'),
            ),
        ],
      ),
      const SizedBox(height: 12),
      AuraGlassSurface(
        radius: 25,
        child: TextField(
          controller: _field,
          onChanged: _changed,
          onSubmitted: (_) {
            _debounce?.cancel();
            if (_field.text.trim().isNotEmpty) _search();
          },
          textInputAction: TextInputAction.search,
          decoration: InputDecoration(
            fillColor: Colors.transparent,
            hintText: 'Brano, artista o link YouTube…',
            prefixIcon: const Icon(Icons.search),
            suffixIcon: IconButton(
              tooltip: 'Cancella',
              onPressed: () {
                _field.clear();
                _changed('');
              },
              icon: const Icon(Icons.close_rounded, size: 18),
            ),
          ),
        ),
      ),
      const SizedBox(height: 15),
      Text(
        'Cerca, scegli, ascolta. Senza chiavi API.',
        style: TextStyle(color: context.muted, fontSize: 13),
      ),
      if (_loading)
        const Padding(
          padding: EdgeInsets.symmetric(vertical: 24),
          child: LinearProgressIndicator(),
        ),
      if (_error != null)
        EmptyMessage(
          icon: Icons.wifi_off_rounded,
          title: 'Un momento di silenzio',
          message: _error!,
          action: OutlinedButton(
            onPressed: _search,
            child: const Text('Riprova'),
          ),
        ),
      if (!_loading && _error == null && _results.isEmpty)
        EmptyMessage(
          icon: Icons.travel_explore_rounded,
          title: _field.text.trim().isEmpty
              ? 'Tutta la musica che cerchi'
              : 'Nessun risultato',
          message: _field.text.trim().isEmpty
              ? 'Scrivi il nome di un artista o di una canzone. I video si riproducono qui, nel player YouTube.'
              : 'Prova con un altro titolo o artista.',
        ),
      ..._results.map(
        (t) => ListTile(
          contentPadding: const EdgeInsets.symmetric(vertical: 5),
          leading: ClipRRect(
            borderRadius: BorderRadius.circular(11),
            child: Image.network(
              t.thumbnail,
              width: 65,
              height: 52,
              fit: BoxFit.cover,
              errorBuilder: (_, _, _) => const SizedBox(
                width: 65,
                height: 52,
                child: Icon(Icons.music_video_rounded),
              ),
            ),
          ),
          title: Text(
            t.title,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
          ),
          subtitle: Text(
            t.artist,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(fontSize: 12, color: context.muted),
          ),
          onTap: () =>
              openOnlinePlayer(context, widget.controller, t, tracks: _results),
          trailing: IconButton(
            tooltip: widget.controller.onlineFavorites.contains(t.id)
                ? 'Rimuovi video dai preferiti'
                : 'Salva video nei preferiti',
            icon: Icon(
              widget.controller.onlineFavorites.contains(t.id)
                  ? Icons.favorite
                  : Icons.favorite_border,
              size: 21,
            ),
            onPressed: () {
              widget.controller.favoriteOnline(t);
              setState(() {});
            },
          ),
        ),
      ),
    ],
  );
}
