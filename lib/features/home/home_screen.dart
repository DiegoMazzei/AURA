import 'package:flutter/material.dart';

import '../../app/aura_controller.dart';
import '../../core/design/aura_design.dart';
import '../../shared/models/music.dart';
import '../library/track_tile.dart';

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
    final listening = controller.recent
        .map(controller.track)
        .whereType<Track>()
        .toList();
    return CustomScrollView(
      key: const PageStorageKey('home'),
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 12),
          sliver: SliverList.list(
            children: [
              Row(
                children: [
                  const Expanded(
                    child: Text(
                      'AURA',
                      style: TextStyle(
                        fontSize: 36,
                        fontWeight: FontWeight.w200,
                        letterSpacing: -1.8,
                      ),
                    ),
                  ),
                  GlassIcon(
                    icon: Icons.search_rounded,
                    label: 'Cerca',
                    onPressed: onSearch,
                    size: 44,
                  ),
                  const SizedBox(width: 10),
                  GlassIcon(
                    icon: Icons.tune_rounded,
                    label: 'Impostazioni',
                    onPressed: onSettings,
                    size: 44,
                  ),
                ],
              ),
              const SizedBox(height: 42),
              SizedBox(
                width: 240,
                child: Text(
                  greeting,
                  style: const TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.w600,
                    letterSpacing: -1.1,
                    height: 1.08,
                  ),
                ),
              ),
              const SizedBox(height: 14),
              Text(
                'La musica rende tutto\npiù leggero.',
                style: TextStyle(
                  fontSize: 15,
                  height: 1.5,
                  color: context.muted,
                ),
              ),
              const SizedBox(height: 28),
              Semantics(
                button: true,
                label: 'Cerca musica, artisti, mood',
                child: GestureDetector(
                  onTap: onSearch,
                  child: AuraGlassSurface(
                    radius: 28,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 17,
                      vertical: 17,
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.search_rounded, size: 22),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Cerca musica, artisti, mood…',
                            style: TextStyle(
                              color: context.muted,
                              fontSize: 14,
                            ),
                          ),
                        ),
                        const Icon(Icons.arrow_forward_ios_rounded, size: 14),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _Shortcut(
                    Icons.auto_awesome_rounded,
                    'Per te',
                    () => controller.playTrack(demoTracks.first),
                    active: true,
                  ),
                  _Shortcut(Icons.explore_outlined, 'Scopri', onExplore),
                  _Shortcut(Icons.blur_on_rounded, 'Atmosfere', onExplore),
                  _Shortcut(Icons.mic_none_rounded, 'Karaoke', onKaraoke),
                ],
              ),
              SectionTitle(
                listening.isEmpty
                    ? 'Il tuo primo ascolto'
                    : 'Continua ad ascoltare',
              ),
              SizedBox(
                height: 96,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: (listening.isEmpty ? controller.tracks : listening)
                      .length,
                  separatorBuilder: (_, _) => const SizedBox(width: 12),
                  itemBuilder: (ctx, i) {
                    final t = (listening.isEmpty
                        ? controller.tracks
                        : listening)[i];
                    return SizedBox(
                      width: 217,
                      child: AuraGlassSurface(
                        radius: 21,
                        child: InkWell(
                          onTap: () => controller.playTrack(t),
                          borderRadius: BorderRadius.circular(21),
                          child: Padding(
                            padding: const EdgeInsets.all(9),
                            child: Row(
                              children: [
                                CosmicCover(
                                  color: Color(t.color),
                                  imageUrl: t.artworkUrl,
                                  size: 72,
                                  radius: 14,
                                ),
                                const SizedBox(width: 11),
                                Expanded(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        t.title,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                          fontSize: 15,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      const SizedBox(height: 5),
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
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SectionTitle('Scegli la tua atmosfera'),
              SizedBox(
                height: 140,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: 4,
                  separatorBuilder: (_, _) => const SizedBox(width: 10),
                  itemBuilder: (_, i) {
                    final names = [
                      'Notte\nChill',
                      'Focus\nProfondo',
                      'Luce\nSoffusa',
                      'Fuori\nOrbita',
                    ];
                    return Semantics(
                      button: true,
                      label: names[i].replaceAll('\n', ' '),
                      child: GestureDetector(
                        onTap: () => controller.playTrack(
                          controller.tracks[i % 2],
                          contextTracks: controller.tracks.take(2).toList(),
                        ),
                        child: CosmicCover(
                          color: [
                            auraViolet,
                            auraBlue,
                            auraPink,
                            const Color(0xffe8b783),
                          ][i],
                          size: 122,
                          title: names[i],
                        ),
                      ),
                    );
                  },
                ),
              ),
              SectionTitle(
                'Il tuo universo',
                action: 'Apri',
                onAction: onLibrary,
              ),
              AuraGlassSurface(
                padding: const EdgeInsets.all(18),
                child: Row(
                  children: [
                    const Icon(Icons.library_music_outlined, size: 28),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Porta qui la tua musica',
                            style: TextStyle(fontWeight: FontWeight.w600),
                          ),
                          const SizedBox(height: 5),
                          Text(
                            'Importa i tuoi file. Ascoltali offline.',
                            style: TextStyle(
                              color: context.muted,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      tooltip: 'Importa audio',
                      onPressed: controller.importing
                          ? null
                          : controller.importAudio,
                      icon: const Icon(Icons.add_rounded),
                    ),
                  ],
                ),
              ),
              const SectionTitle('AURA Originals'),
              ...controller.tracks
                  .take(2)
                  .map((t) => TrackTile(track: t, controller: controller)),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 18),
                child: Text(
                  'YOUR MUSIC. YOUR UNIVERSE.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 10,
                    letterSpacing: 2.6,
                    color: context.muted,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _Shortcut extends StatelessWidget {
  const _Shortcut(this.icon, this.label, this.onTap, {this.active = false});
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool active;
  @override
  Widget build(BuildContext context) => Expanded(
    child: Column(
      children: [
        GlassIcon(
          icon: icon,
          label: label,
          onPressed: onTap,
          active: active,
          size: 50,
        ),
        const SizedBox(height: 8),
        Text(
          label,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 11),
        ),
      ],
    ),
  );
}
