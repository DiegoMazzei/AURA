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
  @override
  Widget build(BuildContext context) {
    final recent = controller.recent
        .map(controller.track)
        .whereType<Track>()
        .toList();
    final collection = controller.libraryTracks;
    return ListView(
      padding: const EdgeInsets.fromLTRB(24, 18, 24, 172),
      children: [
        Row(
          children: [
            const Expanded(
              child: Text(
                'Ascolta',
                style: TextStyle(
                  fontSize: 35,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -1.2,
                ),
              ),
            ),
            GlassIcon(
              icon: Icons.tune_rounded,
              label: 'Impostazioni',
              onPressed: onSettings,
            ),
          ],
        ),
        const SizedBox(height: 26),
        if (collection.isEmpty) ...[
          const SizedBox(height: 30),
          const Text(
            'La tua musica,\nda qui.',
            style: TextStyle(
              fontSize: 40,
              height: 1.08,
              fontWeight: FontWeight.w600,
              letterSpacing: -1.5,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Un artista. I suoi dischi.\nLe canzoni che cerchi.',
            style: TextStyle(fontSize: 18, height: 1.5, color: context.muted),
          ),
          const SizedBox(height: 28),
          Align(
            alignment: Alignment.centerLeft,
            child: FilledButton.icon(
              onPressed: onSearch,
              icon: const Icon(Icons.search),
              label: const Text('Cerca musica'),
            ),
          ),
        ] else ...[
          if (recent.isNotEmpty) ...[
            const SectionTitle('Ascoltati di recente'),
            SizedBox(
              height: 224,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: recent.take(12).length,
                separatorBuilder: (_, _) => const SizedBox(width: 16),
                itemBuilder: (context, i) {
                  final t = recent[i];
                  return SizedBox(
                    width: 154,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(10),
                      onTap: () {
                        controller.playTrack(t, contextTracks: recent);
                        openPlayer(context, controller);
                      },
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          CosmicCover(
                            size: 154,
                            color: Color(t.color),
                            imageUrl: t.artworkUrl,
                            radius: 10,
                          ),
                          const SizedBox(height: 10),
                          Text(
                            t.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 17,
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
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 10),
          ],
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.favorite_rounded),
            title: const Text(
              'Brani del cuore',
              style: TextStyle(fontSize: 19, fontWeight: FontWeight.w600),
            ),
            subtitle: Text('${controller.favorites.length} preferiti'),
            trailing: const Icon(Icons.chevron_right),
            onTap: onLibrary,
          ),
          const SizedBox(height: 12),
          SectionTitle(
            'Nella tua libreria',
            action: 'Tutti',
            onAction: onLibrary,
          ),
          ...collection
              .take(8)
              .map(
                (t) => TrackTile(
                  track: t,
                  controller: controller,
                  onTap: () {
                    controller.playTrack(t, contextTracks: collection);
                    openPlayer(context, controller);
                  },
                ),
              ),
        ],
      ],
    );
  }
}
