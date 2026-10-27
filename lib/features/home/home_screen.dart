import 'package:flutter/material.dart';

import '../../app/aura_controller.dart';
import '../../core/design/aura_design.dart';
import '../../shared/models/music.dart';
import '../library/track_tile.dart';
import '../player/player_screen.dart';

class HomeScreen extends StatelessWidget {
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
  String get greeting {
    final hour = controller.now().hour;
    return hour < 6
        ? 'La notte è tua.'
        : hour < 13
        ? 'Buongiorno, Utente'
        : hour < 18
        ? 'Buon pomeriggio, Utente'
        : 'Buonasera, Utente';
  }

  @override
  Widget build(BuildContext context) {
    final recent = controller.recent
        .map(controller.track)
        .whereType<Track>()
        .toList();
    final listening = recent.isNotEmpty ? recent : controller.libraryTracks;
    final featured = listening.firstOrNull;
    return CustomScrollView(
      key: const PageStorageKey('home'),
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 184),
          sliver: SliverList.list(
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'AURA',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 3,
                            color: context.muted,
                          ),
                        ),
                        const SizedBox(height: 6),
                        const Text(
                          'Ascolta',
                          style: TextStyle(
                            fontSize: 35,
                            fontWeight: FontWeight.w700,
                            letterSpacing: -1.3,
                          ),
                        ),
                      ],
                    ),
                  ),
                  GlassIcon(
                    icon: Icons.search_rounded,
                    label: 'Cerca',
                    onPressed: onSearch,
                  ),
                  const SizedBox(width: 10),
                  GlassIcon(
                    icon: Icons.tune_rounded,
                    label: 'Impostazioni',
                    onPressed: onSettings,
                  ),
                ],
              ),
              const SizedBox(height: 26),
              Text(
                greeting,
                style: TextStyle(fontSize: 15, color: context.muted),
              ),
              const SizedBox(height: 8),
              const Text(
                'Il tuo spazio.\nLa tua musica.',
                style: TextStyle(
                  fontSize: 32,
                  height: 1.13,
                  fontWeight: FontWeight.w500,
                  letterSpacing: -1,
                ),
              ),
              const SizedBox(height: 26),
              if (featured == null)
                AuraGlassSurface(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Da dove cominciamo?',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'Cerca un artista o una canzone. La tua musica prende forma da qui.',
                      ),
                      const SizedBox(height: 18),
                      FilledButton.icon(
                        onPressed: onSearch,
                        icon: const Icon(Icons.search),
                        label: const Text('Cerca musica'),
                      ),
                    ],
                  ),
                ),
              if (featured != null)
                GestureDetector(
                  onTap: () {
                    controller.playTrack(featured, contextTracks: listening);
                    openPlayer(context, controller);
                  },
                  child: Semantics(
                    button: true,
                    label: 'Riproduci ${featured.title}',
                    child: AspectRatio(
                      aspectRatio: 1.65,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            CosmicCover(
                              size: 400,
                              color: Color(featured.color),
                              imageUrl: featured.artworkUrl,
                              radius: 0,
                            ),
                            const DecoratedBox(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                  colors: [
                                    Colors.transparent,
                                    Color(0xd9000000),
                                  ],
                                ),
                              ),
                            ),
                            Positioned(
                              left: 22,
                              right: 22,
                              bottom: 21,
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'RIPRENDI DA QUI',
                                          style: const TextStyle(
                                            color: Colors.white70,
                                            fontSize: 10,
                                            fontWeight: FontWeight.w600,
                                            letterSpacing: 2,
                                          ),
                                        ),
                                        const SizedBox(height: 7),
                                        Text(
                                          featured.title,
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 27,
                                            fontWeight: FontWeight.w700,
                                            letterSpacing: -.6,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          featured.artist,
                                          maxLines: 1,
                                          style: const TextStyle(
                                            color: Colors.white70,
                                            fontSize: 13,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  const Icon(
                                    Icons.play_circle_fill_rounded,
                                    size: 42,
                                    color: Colors.white,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              if (listening.isNotEmpty)
                SectionTitle(
                  recent.isEmpty ? 'Per cominciare' : 'Ascoltati di recente',
                  action: 'Tutti',
                  onAction: onLibrary,
                ),
              if (listening.isNotEmpty)
                SizedBox(
                  height: 217,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: listening.length,
                    itemBuilder: (context, i) {
                      final t = listening[i];
                      return SizedBox(
                        width: 154,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(10),
                          onTap: () {
                            controller.playTrack(t, contextTracks: listening);
                            openPlayer(context, controller);
                          },
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              CosmicCover(
                                size: 154,
                                color: Color(t.color),
                                imageUrl: t.artworkUrl,
                                radius: 9,
                              ),
                              const SizedBox(height: 9),
                              Text(
                                t.title,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(height: 3),
                              Text(
                                t.artist,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: context.muted,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                    separatorBuilder: (_, _) => const SizedBox(width: 14),
                  ),
                ),
              const SectionTitle('Fatti per restare'),
              AuraGlassSurface(
                radius: 14,
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 8,
                  ),
                  leading: Icon(
                    Icons.favorite_rounded,
                    color: Theme.of(context).colorScheme.primary,
                    size: 29,
                  ),
                  title: const Text(
                    'Brani del cuore',
                    style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
                  ),
                  subtitle: Text('${controller.favorites.length} preferiti'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: onLibrary,
                ),
              ),
              SectionTitle(
                'La tua raccolta',
                action: 'Apri',
                onAction: onLibrary,
              ),
              ...controller.libraryTracks
                  .take(4)
                  .map(
                    (t) => TrackTile(
                      track: t,
                      controller: controller,
                      onTap: () => controller.playTrack(
                        t,
                        contextTracks: controller.libraryTracks,
                      ),
                    ),
                  ),
              const SizedBox(height: 20),
              Text(
                'YOUR MUSIC. YOUR UNIVERSE.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: context.muted.withValues(alpha: .4),
                  fontSize: 9,
                  letterSpacing: 2,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
