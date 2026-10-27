import 'package:flutter/material.dart';

import '../../app/aura_controller.dart';
import '../../core/artwork/music_image.dart';
import '../../core/catalog/artist_recommendations.dart';
import '../../core/catalog/musicbrainz_catalog.dart' show normalizeMusicText;
import '../../core/design/aura_design.dart';
import '../catalog/catalog_screen.dart';
import '../player/player_screen.dart' show MiniPlayer;

void openArtistDiscovery(
  BuildContext context,
  AuraController controller, {
  SuggestedArtist? seed,
  List<SuggestedArtist> starters = const [],
}) => Navigator.of(context).push(
  MaterialPageRoute<void>(
    builder: (_) => ArtistDiscoveryScreen(
      controller: controller,
      seed: seed,
      starters: starters,
    ),
  ),
);

class ArtistDiscoveryScreen extends StatefulWidget {
  const ArtistDiscoveryScreen({
    super.key,
    required this.controller,
    this.seed,
    this.starters = const [],
  });
  final AuraController controller;
  final SuggestedArtist? seed;
  final List<SuggestedArtist> starters;
  @override
  State<ArtistDiscoveryScreen> createState() => _ArtistDiscoveryScreenState();
}

class _ArtistDiscoveryScreenState extends State<ArtistDiscoveryScreen> {
  final _scroll = ScrollController();
  SuggestedArtist? _selected;
  Future<List<SuggestedArtist>>? _results;
  final _trail = <SuggestedArtist>[];
  bool _opening = false;
  @override
  void initState() {
    super.initState();
    if (widget.seed != null) _choose(widget.seed!, initial: true);
  }

  void _choose(SuggestedArtist artist, {bool initial = false}) {
    void update() {
      _selected = artist;
      _trail.removeWhere((a) => a.key == artist.key);
      _trail.add(artist);
      if (_trail.length > 8) _trail.removeAt(0);
      _results = widget.controller.artistRecommendations!.related(artist);
    }

    if (initial) {
      update();
    } else {
      setState(update);
      if (_scroll.hasClients) {
        _scroll.animateTo(
          0,
          duration: MediaQuery.disableAnimationsOf(context)
              ? Duration.zero
              : const Duration(milliseconds: 240),
          curve: Curves.easeOut,
        );
      }
    }
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  Future<void> _openArtist() async {
    if (_opening || _selected == null) return;
    final name = _selected!.name;
    setState(() => _opening = true);
    try {
      final artists = await widget.controller.artistDirectory!.searchArtists(
        name,
      );
      if (!mounted) return;
      final exact = artists
          .where((a) => normalizeMusicText(a.name) == normalizeMusicText(name))
          .firstOrNull;
      if (exact == null) throw StateError('missing');
      openCatalogArtist(context, widget.controller, exact);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Pagina artista non disponibile. Riprova.'),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _opening = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Scopri artisti')),
    bottomNavigationBar: ListenableBuilder(
      listenable: widget.controller,
      builder: (_, _) => widget.controller.hasCurrent
          ? SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(18, 6, 18, 8),
                child: MiniPlayer(controller: widget.controller),
              ),
            )
          : const SizedBox.shrink(),
    ),
    body: AuraBackground(
      child: ListView(
        controller: _scroll,
        padding: const EdgeInsets.fromLTRB(22, 12, 22, 40),
        children: [
          Text(
            _selected == null
                ? 'Segui il tuo suono.'
                : 'Se ti piace ${_selected!.name}',
            style: const TextStyle(
              fontSize: 30,
              fontWeight: FontWeight.w600,
              letterSpacing: -.8,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'Tocca un artista per scoprirne altri simili.',
            style: TextStyle(color: context.muted),
          ),
          if (_trail.isNotEmpty) ...[
            const SizedBox(height: 20),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              reverse: true,
              child: Row(
                children: [
                  for (final artist in _trail)
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ActionChip(
                        avatar: artist.key == _selected?.key
                            ? const Icon(Icons.graphic_eq, size: 16)
                            : null,
                        label: Text(artist.name),
                        onPressed: () => _choose(artist),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            AuraDashboardPanel(
              child: Row(
                children: [
                  MusicImage(
                    controller: widget.controller,
                    artist: _selected!.name,
                    portrait: true,
                    fallbackUrl: _selected!.imageUrl,
                    size: 68,
                    radius: 34,
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _selected!.name,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        TextButton.icon(
                          onPressed:
                              _opening ||
                                  widget.controller.artistDirectory == null
                              ? null
                              : _openArtist,
                          icon: const Icon(Icons.arrow_outward, size: 16),
                          label: Text(_opening ? 'Apro…' : 'Apri artista'),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 26),
          if (_results == null)
            _grid(
              widget.starters.isEmpty
                  ? const [
                      SuggestedArtist(name: 'Gemitaiz'),
                      SuggestedArtist(name: 'Ernia'),
                      SuggestedArtist(name: 'The Weeknd'),
                      SuggestedArtist(name: 'Dua Lipa'),
                      SuggestedArtist(name: 'Taylor Swift'),
                      SuggestedArtist(name: 'Marracash'),
                    ]
                  : widget.starters,
            )
          else
            FutureBuilder<List<SuggestedArtist>>(
              key: ValueKey(_selected!.key),
              future: _results,
              builder: (context, snapshot) {
                if (snapshot.connectionState != ConnectionState.done) {
                  return const Padding(
                    padding: EdgeInsets.all(36),
                    child: Center(child: CircularProgressIndicator()),
                  );
                }
                if (snapshot.hasError) {
                  return _message(
                    'Non riesco a caricare i suggerimenti.',
                    retry: true,
                  );
                }
                final artists = snapshot.data ?? [];
                if (artists.isEmpty) {
                  return _message(
                    'Non ci sono ancora suggerimenti per questo artista.',
                  );
                }
                return _grid(artists);
              },
            ),
        ],
      ),
    ),
  );
  Widget _message(String text, {bool retry = false}) => Column(
    children: [
      Text(text, textAlign: TextAlign.center),
      const SizedBox(height: 12),
      if (retry)
        OutlinedButton(
          onPressed: () => _choose(_selected!),
          child: const Text('Riprova'),
        ),
      TextButton(
        onPressed: () => setState(() {
          _selected = null;
          _results = null;
          _trail.clear();
        }),
        child: const Text('Riparti dagli artisti iniziali'),
      ),
    ],
  );
  Widget _grid(List<SuggestedArtist> artists) => LayoutBuilder(
    builder: (context, constraints) {
      final count = constraints.maxWidth < 350 ? 2 : 3;
      final size = ((constraints.maxWidth - (count - 1) * 18) / count).clamp(
        60.0,
        120.0,
      );
      return Wrap(
        spacing: 18,
        runSpacing: 24,
        children: [
          for (final artist in artists)
            SizedBox(
              width: (constraints.maxWidth - (count - 1) * 18) / count,
              child: InkWell(
                borderRadius: BorderRadius.circular(18),
                onTap: () => _choose(artist),
                child: Column(
                  children: [
                    MusicImage(
                      controller: widget.controller,
                      artist: artist.name,
                      portrait: true,
                      fallbackUrl: artist.imageUrl,
                      size: size,
                      radius: size / 2,
                    ),
                    const SizedBox(height: 10),
                    Text(
                      artist.name,
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      );
    },
  );
}
