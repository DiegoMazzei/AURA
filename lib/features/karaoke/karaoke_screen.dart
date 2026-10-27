import 'package:flutter/material.dart';

import '../../app/aura_controller.dart';
import '../../core/design/aura_design.dart';
import '../player/player_screen.dart';
import 'lyrics_search_sheet.dart';

class KaraokeScreen extends StatefulWidget {
  const KaraokeScreen({super.key, required this.controller});
  final AuraController controller;
  @override
  State<KaraokeScreen> createState() => _KaraokeScreenState();
}

class _KaraokeScreenState extends State<KaraokeScreen> {
  final ScrollController _scroll = ScrollController();
  List<GlobalKey> _keys = [];
  int _active = -1;
  double _offset = 0, _fontSize = 30;
  String _trackId = '';
  bool _immersive = false;
  @override
  void initState() {
    super.initState();
    widget.controller.audio.addListener(_follow);
    widget.controller.addListener(_follow);
    _sync();
    _follow();
  }

  void _sync() {
    final t = widget.controller.current;
    if (_trackId != t.id || _keys.length != t.lyrics.length) {
      _trackId = t.id;
      _keys = List.generate(t.lyrics.length, (_) => GlobalKey());
      _active = -1;
    }
  }

  void _follow() {
    if (!mounted) return;
    _sync();
    final time =
        widget.controller.position.inMilliseconds + (_offset * 1000).round();
    final lines = widget.controller.current.lyrics;
    var next = -1;
    for (var i = 0; i < lines.length; i++) {
      if (lines[i].at.inMilliseconds <= time) next = i;
    }
    if (next != _active) {
      setState(() => _active = next);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted || next < 0 || next >= _keys.length) return;
        final ctx = _keys[next].currentContext;
        if (ctx != null) {
          Scrollable.ensureVisible(
            ctx,
            alignment: .38,
            duration: MediaQuery.disableAnimationsOf(context)
                ? Duration.zero
                : const Duration(milliseconds: 500),
            curve: Curves.easeOutCubic,
          );
        }
      });
    }
  }

  @override
  void dispose() {
    widget.controller.audio.removeListener(_follow);
    widget.controller.removeListener(_follow);
    _scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: widget.controller,
    builder: (_, _) {
      final c = widget.controller;
      _sync();
      final t = c.current;
      return Scaffold(
        body: AuraBackground(
          color: Theme.of(context).colorScheme.primary,
          artwork: false,
          child: SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 10),
                  child: Row(
                    children: [
                      GlassIcon(
                        icon: Icons.arrow_back_ios_new_rounded,
                        label: 'Indietro',
                        onPressed: () => Navigator.pop(context),
                      ),
                      const SizedBox(width: 12),
                      CosmicCover(
                        color: Color(t.color),
                        imageUrl: t.artworkUrl,
                        size: 40,
                        radius: 10,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              t.title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            Text(
                              t.artist,
                              style: TextStyle(
                                fontSize: 12,
                                color: context.muted,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        tooltip: 'Trova testi',
                        onPressed: () => findLyrics(context, c, t),
                        icon: const Icon(Icons.note_add_outlined),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 26,
                    vertical: 12,
                  ),
                  child: AuraGlassSurface(
                    radius: 22,
                    child: Row(
                      children: [
                        Expanded(
                          child: TextButton(
                            onPressed: () => setState(() => _immersive = false),
                            child: Text(
                              'Testi',
                              style: TextStyle(
                                color: !_immersive
                                    ? Theme.of(context).colorScheme.primary
                                    : context.muted,
                              ),
                            ),
                          ),
                        ),
                        Expanded(
                          child: TextButton(
                            onPressed: t.lyrics.isEmpty
                                ? null
                                : () => setState(() => _immersive = true),
                            child: Text(
                              'Karaoke',
                              style: TextStyle(
                                color: _immersive
                                    ? Theme.of(context).colorScheme.primary
                                    : context.muted,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                if (t.id == 'aura-orbit')
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 30,
                      vertical: 6,
                    ),
                    child: Text(
                      'Testo originale dimostrativo · base strumentale',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 11, color: context.muted),
                    ),
                  ),
                if (t.lyricsSource.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Text(
                      '${t.lyricsSource} · ${t.lyrics.isEmpty ? 'Testo' : 'Sincronizzato'}',
                      style: TextStyle(color: context.muted, fontSize: 11),
                    ),
                  ),
                Expanded(
                  child: t.lyrics.isEmpty && t.plainLyrics.isEmpty
                      ? Center(
                          child: EmptyMessage(
                            icon: Icons.lyrics_outlined,
                            title: 'Dai parole alla tua musica',
                            message: 'Cerca i testi e scegli la versione del tuo brano.',
                            action: FilledButton.icon(
                              onPressed: () => findLyrics(context, c, t),
                              icon: const Icon(Icons.add),
                              label: const Text('Trova testi'),
                            ),
                          ),
                        )
                      : t.lyrics.isEmpty
                      ? SingleChildScrollView(
                          padding: const EdgeInsets.fromLTRB(30, 24, 30, 60),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Testo non sincronizzato',
                                style: TextStyle(
                                  color: context.muted,
                                  fontSize: 12,
                                ),
                              ),
                              const SizedBox(height: 20),
                              Text(
                                t.plainLyrics,
                                style: TextStyle(
                                  fontSize: _fontSize,
                                  height: 1.45,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        )
                      : ListView(
                          controller: _scroll,
                          padding: const EdgeInsets.fromLTRB(30, 35, 30, 80),
                          children: [
                            for (var i = 0; i < t.lyrics.length; i++)
                              Padding(
                                key: _keys[i],
                                padding: const EdgeInsets.only(bottom: 23),
                                child: GestureDetector(
                                  onTap: () => c.seek(
                                    t.lyrics[i].at -
                                        Duration(
                                          milliseconds: (_offset * 1000)
                                              .round(),
                                        ),
                                  ),
                                  child: AnimatedDefaultTextStyle(
                                    duration:
                                        MediaQuery.disableAnimationsOf(context)
                                        ? Duration.zero
                                        : const Duration(milliseconds: 300),
                                    style: TextStyle(
                                      fontSize:
                                          _fontSize + (_immersive ? 5 : 0),
                                      height: 1.28,
                                      fontWeight: FontWeight.w700,
                                      letterSpacing: -.8,
                                      color: i == _active
                                          ? context.ink
                                          : context.ink.withValues(
                                              alpha: i < _active ? .3 : .48,
                                            ),
                                    ),
                                    child: Text(t.lyrics[i].text),
                                  ),
                                ),
                              ),
                          ],
                        ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 0, 24, 20),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          IconButton(
                            tooltip: 'Riduci testo',
                            onPressed: () => setState(
                              () => _fontSize = (_fontSize - 2).clamp(22, 42),
                            ),
                            icon: const Icon(Icons.text_decrease),
                          ),
                          const SizedBox(width: 16),
                          PlayButton(controller: c),
                          const SizedBox(width: 16),
                          IconButton(
                            tooltip: 'Ingrandisci testo',
                            onPressed: () => setState(
                              () => _fontSize = (_fontSize + 2).clamp(22, 42),
                            ),
                            icon: const Icon(Icons.text_increase),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      AuraGlassSurface(
                        radius: 24,
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        child: Row(
                          children: [
                            Text(
                              'Sincronia',
                              style: TextStyle(
                                fontSize: 11,
                                color: context.muted,
                              ),
                            ),
                            Expanded(
                              child: Slider(
                                value: _offset,
                                min: -5,
                                max: 5,
                                divisions: 100,
                                label: '${_offset.toStringAsFixed(1)} s',
                                onChanged: (v) {
                                  setState(() => _offset = v);
                                  _follow();
                                },
                              ),
                            ),
                            Text(
                              '${_offset > 0 ? '+' : ''}${_offset.toStringAsFixed(1)} s',
                              style: const TextStyle(fontSize: 11),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Testi sincronizzati · nessuna rimozione della voce',
                        style: TextStyle(fontSize: 10, color: context.muted),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    },
  );
}
