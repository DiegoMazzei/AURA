import 'package:flutter/material.dart';

import '../../app/aura_controller.dart';
import '../../core/design/aura_design.dart';
import '../library/library_groups.dart';
import '../youtube/online_search_screen.dart';

class SearchScreen extends StatelessWidget {
  const SearchScreen({
    super.key,
    required this.controller,
    this.explore = false,
  });
  final AuraController controller;
  final bool explore;
  @override
  Widget build(BuildContext context) {
    if (!explore) {
      return OnlineSearchScreen(controller: controller, showLocalLink: false);
    }
    final artists = groupByArtist(controller.libraryTracks);
    final albums = groupByAlbum(controller.libraryTracks)
        .where((g) => !g.unknownAlbum)
        .toList();
    return ListView(
      key: const PageStorageKey('explore'),
      padding: const EdgeInsets.fromLTRB(24, 18, 24, 184),
      children: [
        const Text(
          'Esplora',
          style: TextStyle(
            fontSize: 35,
            fontWeight: FontWeight.w700,
            letterSpacing: -1.2,
          ),
        ),
        const SizedBox(height: 9),
        Text(
          'Ritrova chi ti fa sentire qualcosa.',
          style: TextStyle(color: context.muted),
        ),
        const SectionTitle('I tuoi artisti'),
        ...artists.map(
          (group) => ListTile(
            contentPadding: const EdgeInsets.symmetric(vertical: 7),
            leading: ClipOval(
              child: CosmicCover(
                size: 54,
                imageUrl: group.tracks.first.artworkUrl,
                color: Color(group.tracks.first.color),
              ),
            ),
            title: Text(
              group.name,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            subtitle: Text(group.subtitle),
            trailing: const Icon(Icons.play_circle_outline_rounded),
            onTap: () => controller.playTrack(
              group.tracks.first,
              contextTracks: group.tracks,
            ),
          ),
        ),
        const SectionTitle('Album nella tua raccolta'),
        Wrap(
          spacing: 16,
          runSpacing: 20,
          children: albums.map((group) {
            final size =
                (MediaQuery.sizeOf(context).width.clamp(0, 720) - 64) / 2;
            return SizedBox(
              width: size,
              child: InkWell(
                onTap: () => controller.playTrack(
                  group.tracks.first,
                  contextTracks: group.tracks,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CosmicCover(
                      size: size,
                      imageUrl: group.tracks.first.artworkUrl,
                      color: Color(group.tracks.first.color),
                      radius: 10,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      group.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: FontWeight.w500),
                    ),
                    Text(
                      group.subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(color: context.muted, fontSize: 12),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}
