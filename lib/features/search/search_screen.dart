import 'dart:async';

import 'package:flutter/material.dart';

import '../../app/aura_controller.dart';
import '../../core/design/aura_design.dart';
import '../library/track_tile.dart';
import '../youtube/online_search_screen.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({
    super.key,
    required this.controller,
    this.explore = false,
  });
  final AuraController controller;
  final bool explore;
  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final _field = TextEditingController();
  Timer? _debounce;
  String _query = '', _filter = 'Tutto';
  bool _online = true;
  @override
  void dispose() {
    _debounce?.cancel();
    _field.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = widget.controller;
    if (_online && !widget.explore) {
      return OnlineSearchScreen(
        controller: c,
        onLocal: () => setState(() => _online = false),
      );
    }
    final q = _query.toLowerCase();
    final results = c.tracks
        .where((t) => '${t.title} ${t.artist}'.toLowerCase().contains(q))
        .toList();
    final artists = c.tracks
        .map((t) => t.artist)
        .toSet()
        .where((v) => v.toLowerCase().contains(q))
        .toList();
    final playlists = c.playlists
        .where((p) => p.name.toLowerCase().contains(q))
        .toList();
    return ListView(
      key: PageStorageKey(widget.explore ? 'explore' : 'search'),
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
      children: [
        Text(
          widget.explore ? 'Esplora' : 'Cerca',
          style: const TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.w600,
            letterSpacing: -1,
          ),
        ),
        if (!widget.explore)
          TextButton(
            onPressed: () => setState(() => _online = true),
            child: const Text('Cerca su YouTube'),
          ),
        const SizedBox(height: 20),
        AuraGlassSurface(
          radius: 25,
          child: TextField(
            controller: _field,
            textInputAction: TextInputAction.search,
            onChanged: (value) {
              _debounce?.cancel();
              _debounce = Timer(
                const Duration(milliseconds: 220),
                () => setState(() => _query = value.trim()),
              );
            },
            decoration: InputDecoration(
              hintText: 'Artisti, canzoni, playlist…',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: IconButton(
                tooltip: 'Cancella ricerca',
                onPressed: () {
                  _field.clear();
                  setState(() => _query = '');
                },
                icon: const Icon(Icons.close, size: 18),
              ),
              fillColor: Colors.transparent,
            ),
          ),
        ),
        const SizedBox(height: 14),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: ['Tutto', 'Brani', 'Artisti', 'Playlist']
                .map(
                  (label) => Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text(label),
                      selected: _filter == label,
                      onSelected: (_) => setState(() => _filter = label),
                    ),
                  ),
                )
                .toList(),
          ),
        ),
        if (_query.isEmpty) ...[
          const SectionTitle('Scopri per atmosfera'),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: 6,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: 10,
              crossAxisSpacing: 10,
              childAspectRatio: 1.9,
            ),
            itemBuilder: (_, i) => GestureDetector(
              onTap: () => c.playTrack(
                c.tracks[i % 2],
                contextTracks: c.tracks.take(2).toList(),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(19),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Image.asset(
                      'assets/images/cosmic-ribbon.png',
                      fit: BoxFit.cover,
                      alignment: Alignment(i.isEven ? -1 : 1, i / 3 - 1),
                    ),
                    ColoredBox(
                      color: [
                        auraPink,
                        auraBlue,
                        auraViolet,
                        const Color(0xff789b8c),
                        const Color(0xffe29b79),
                        auraPink,
                      ][i].withValues(alpha: .3),
                    ),
                    const DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Colors.black54, Colors.transparent],
                        ),
                      ),
                    ),
                    Positioned(
                      left: 15,
                      bottom: 14,
                      child: Text(
                        [
                          'Chill',
                          'Energia',
                          'Notte',
                          'Focus',
                          'Luce',
                          'Sognare',
                        ][i],
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(top: 9),
            child: Text(
              'Atmosfere dimostrative · AURA Originals',
              style: TextStyle(fontSize: 11, color: context.muted),
            ),
          ),
        ],
        if (_filter == 'Tutto' || _filter == 'Brani') ...[
          SectionTitle(
            _query.isEmpty ? 'La tua musica' : 'Brani · ${results.length}',
          ),
          ...results.map(
            (t) => TrackTile(
              track: t,
              controller: c,
              onTap: () => c.playTrack(t, contextTracks: results),
            ),
          ),
        ],
        if (_filter == 'Artisti' ||
            (_filter == 'Tutto' && _query.isNotEmpty)) ...[
          const SectionTitle('Artisti'),
          ...artists.map(
            (artist) => ListTile(
              leading: const Icon(Icons.person_outline),
              title: Text(artist),
              subtitle: const Text('Nella tua libreria'),
              onTap: () {
                final tracks = c.tracks
                    .where((t) => t.artist == artist)
                    .toList();
                c.playTrack(tracks.first, contextTracks: tracks);
              },
            ),
          ),
        ],
        if (_filter == 'Playlist' ||
            (_filter == 'Tutto' && _query.isNotEmpty)) ...[
          const SectionTitle('Playlist'),
          ...playlists.map(
            (p) => ListTile(
              leading: const Icon(Icons.queue_music),
              title: Text(p.name),
              subtitle: Text('${p.trackIds.length} brani'),
              onTap: p.trackIds.isEmpty
                  ? null
                  : () {
                      final tracks = c.tracksFor(p);
                      c.playTrack(tracks.first, contextTracks: tracks);
                    },
            ),
          ),
        ],
        if ((results.isEmpty && artists.isEmpty && playlists.isEmpty) ||
            (_filter == 'Playlist' && playlists.isEmpty))
          const EmptyMessage(
            icon: Icons.search_off,
            title: 'Nessun risultato',
            message: 'Cerca nella tua libreria o importa nuovi file audio.',
          ),
        const SizedBox(height: 24),
        AuraGlassSurface(
          padding: const EdgeInsets.all(18),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.public_outlined),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Un universo ancora più grande',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 7),
                    Text(
                      'La ricerca online YouTube non è ancora collegata. Qui trovi i file locali e gli originali AURA.',
                      style: TextStyle(
                        fontSize: 13,
                        color: context.muted,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
