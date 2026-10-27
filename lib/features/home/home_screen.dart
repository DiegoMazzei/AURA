import 'package:flutter/material.dart';

import '../../app/aura_controller.dart';
import '../../core/artwork/music_image.dart';
import '../../core/catalog/artist_directory.dart';
import '../../core/design/aura_design.dart';
import '../../shared/models/music.dart';
import '../catalog/catalog_screen.dart';
import '../discovery/artist_discovery_screen.dart';
import '../../core/catalog/artist_recommendations.dart';
import '../player/player_screen.dart';

const discoveryArtists = [
  DirectoryArtist(id: 441911933, name: 'Gemitaiz', genre: 'Hip-Hop/Rap'),
  DirectoryArtist(id: 479756766, name: 'The Weeknd', genre: 'R&B/Soul'),
  DirectoryArtist(id: 159260351, name: 'Taylor Swift', genre: 'Pop'),
  DirectoryArtist(id: 271256, name: 'Drake', genre: 'Hip-Hop/Rap'),
];

class HomeScreen extends StatefulWidget {
  const HomeScreen({
    super.key,
    required this.controller,
    required this.onSearch,
    required this.onExplore,
    required this.onLibrary,
    required this.onKaraoke,
    required this.onSettings,
  });
  final AuraController controller;
  final VoidCallback onSearch, onExplore, onLibrary, onKaraoke, onSettings;
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _filter = 0;
  late final Future<DirectoryResults> _suggestions =
      widget.controller.artistDirectory?.search('Gemitaiz') ??
      Future.value(const DirectoryResults());
  @override
  Widget build(BuildContext context) {
    final c = widget.controller;
    final recent = c.recent.map(c.track).whereType<Track>().toList();
    final artists = c.favoriteArtists.isNotEmpty
        ? c.favoriteArtists.values.toList()
        : discoveryArtists;
    final hour = c.now().hour;
    final greeting = hour < 12
        ? 'Buongiorno,'
        : hour < 18
        ? 'Buon pomeriggio,'
        : 'Buonasera,';
    return ListView(
      padding: const EdgeInsets.fromLTRB(18, 24, 18, 172),
      children: [
        Row(
          children: [
            Container(
              width: 43,
              height: 43,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [
                    Theme.of(context).colorScheme.primary,
                    Theme.of(context).colorScheme.primaryContainer,
                  ],
                ),
              ),
              child: Center(
                child: Text(
                  c.displayName.isEmpty
                      ? 'A'
                      : c.displayName.characters.first.toUpperCase(),
                  style: TextStyle(
                    fontSize: 25,
                    color: Theme.of(context).colorScheme.onPrimary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    c.displayName.isEmpty ? 'Benvenuto' : greeting,
                    style: TextStyle(fontSize: 18, color: context.muted),
                  ),
                  Text(
                    c.displayName.isEmpty ? 'La tua musica' : c.displayName,
                    style: const TextStyle(
                      fontSize: 23,
                      height: 1.15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
            GlassIcon(
              icon: Icons.tune_rounded,
              label: 'Impostazioni',
              onPressed: widget.onSettings,
            ),
          ],
        ),
        const SizedBox(height: 24),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              for (var i = 0; i < 3; i++)
                Padding(
                  padding: const EdgeInsets.only(right: 10),
                  child: ChoiceChip(
                    label: Text(['Tutto', 'Musica', 'Artisti'][i]),
                    selected: _filter == i,
                    selectedColor: Theme.of(context)
                        .colorScheme
                        .primaryContainer,
                    showCheckmark: false,
                    labelStyle: TextStyle(
                      color: _filter == i
                          ? Theme.of(context).colorScheme.onPrimaryContainer
                          : context.ink,
                      fontSize: 15,
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 13,
                      vertical: 8,
                    ),
                    onSelected: (_) => setState(() => _filter = i),
                  ),
                ),
            ],
          ),
        ),
        if (_filter != 2)
          FutureBuilder<DirectoryResults>(
            future: _suggestions,
            builder: (context, snapshot) {
              final albums =
                  snapshot.data?.albums.take(8).toList() ?? <DirectoryAlbum>[];
              if (recent.isEmpty && albums.isEmpty) {
                if (c.artistDirectory != null && !snapshot.hasError) {
                  return const Padding(
                    padding: EdgeInsets.symmetric(vertical: 28),
                    child: LinearProgressIndicator(minHeight: 2),
                  );
                }
                return const SizedBox.shrink();
              }
              return Padding(
                padding: const EdgeInsets.only(top: 26),
                child: AuraDashboardPanel(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _HomeHeading(
                        'In primo piano',
                        action: 'Cerca',
                        onAction: widget.onSearch,
                      ),
                      SizedBox(
                        height: 216,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          itemCount: recent.take(6).length + albums.length,
                          separatorBuilder: (_, _) => const SizedBox(width: 16),
                          itemBuilder: (context, i) {
                            final count = recent.take(6).length;
                            final t = i < count ? recent[i] : null;
                            final a = i >= count ? albums[i - count] : null;
                            return SizedBox(
                              width: 150,
                              child: InkWell(
                                borderRadius: BorderRadius.circular(14),
                                onTap: () {
                                  if (t != null) {
                                    c.playTrack(t, contextTracks: recent);
                                    openPlayer(context, c);
                                  } else {
                                    openCatalogAlbum(context, c, a!);
                                  }
                                },
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    MusicImage(
                                      controller: c,
                                      artist:
                                          t?.catalogIdentity?.albumArtist ??
                                          t?.artist ??
                                          a!.artist,
                                      album: t?.album ?? a!.title,
                                      fallbackUrl: t?.artworkUrl,
                                      size: 150,
                                      radius: 12,
                                    ),
                                    const SizedBox(height: 10),
                                    Text(
                                      t?.title ?? a!.title,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    const SizedBox(height: 3),
                                    Text(
                                      t?.artist ?? a!.artist,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        fontSize: 13,
                                        color: context.muted,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        if (_filter != 1 && c.artistDirectory != null)
          Padding(
            padding: const EdgeInsets.only(top: 18),
            child: AuraDashboardPanel(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _HomeHeading(
                    c.favoriteArtists.isEmpty
                        ? 'Scopri artisti'
                        : 'Artisti preferiti',
                    action: c.artistRecommendations == null
                        ? 'Cerca'
                        : 'Esplora',
                    onAction: c.artistRecommendations == null
                        ? widget.onSearch
                        : () => openArtistDiscovery(
                            context,
                            c,
                            starters: artists
                                .map((a) => SuggestedArtist(name: a.name))
                                .toList(),
                          ),
                  ),
                  SizedBox(
                    height: 134,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: artists.length,
                      separatorBuilder: (_, _) => const SizedBox(width: 18),
                      itemBuilder: (context, i) {
                        final a = artists[i];
                        return SizedBox(
                          width: 88,
                          child: InkWell(
                            borderRadius: BorderRadius.circular(44),
                            onTap: () => openCatalogArtist(context, c, a),
                            child: Column(
                              children: [
                                MusicImage(
                                  controller: c,
                                  artist: a.name,
                                  portrait: true,
                                  size: 88,
                                  radius: 44,
                                ),
                                const SizedBox(height: 10),
                                Text(
                                  a.name,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        if (_filter != 2 && recent.isNotEmpty) ...[
          const _HomeHeading('Continua ad ascoltare'),
          ...recent
              .take(4)
              .map(
                (t) => ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: MusicImage(
                    controller: c,
                    artist: t.catalogIdentity?.albumArtist ?? t.artist,
                    album: t.album,
                    fallbackUrl: t.artworkUrl,
                    size: 48,
                    radius: 9,
                  ),
                  title: Text(
                    t.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  subtitle: Text(
                    t.artist,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  trailing: const Icon(Icons.play_arrow_rounded),
                  onTap: () {
                    c.playTrack(t, contextTracks: recent);
                    openPlayer(context, c);
                  },
                ),
              ),
        ] else if (_filter != 2 && c.artistDirectory != null)
          FutureBuilder<DirectoryResults>(
            future: _suggestions,
            builder: (context, snapshot) {
              if (!snapshot.hasData) return const SizedBox.shrink();
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const _HomeHeading('Dal catalogo'),
                  ...snapshot.data!.songs
                      .take(5)
                      .map(
                        (s) => SongRow(
                          song: s,
                          controller: c,
                          onTap: () => openCatalogSong(context, c, s),
                        ),
                      ),
                ],
              );
            },
          ),
        if (c.artistDirectory == null && recent.isEmpty) ...[
          const SizedBox(height: 26),
          const Text(
            'La tua prossima canzone\nti aspetta.',
            style: TextStyle(fontSize: 28, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 20),
          Align(
            alignment: Alignment.centerLeft,
            child: FilledButton.icon(
              onPressed: widget.onSearch,
              icon: const Icon(Icons.search),
              label: const Text('Cerca musica'),
            ),
          ),
        ],
      ],
    );
  }
}

class _HomeHeading extends StatelessWidget {
  const _HomeHeading(this.title, {this.action, this.onAction});
  final String title;
  final String? action;
  final VoidCallback? onAction;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 14),
    child: Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w500,
              letterSpacing: -.4,
            ),
          ),
        ),
        if (action != null)
          TextButton(onPressed: onAction, child: Text(action!)),
      ],
    ),
  );
}
