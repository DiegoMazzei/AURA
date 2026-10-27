import 'package:flutter/material.dart';

import '../../app/aura_controller.dart';
import '../../core/design/aura_design.dart';
import '../library/track_tile.dart';
import 'online_player_screen.dart';
import 'online_track.dart';

class OnlineLibraryScreen extends StatelessWidget {
  const OnlineLibraryScreen({super.key, required this.controller});
  final AuraController controller;
  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: controller,
    builder: (_, _) {
      final c = controller;
      final favorites = c.onlineFavorites
          .map((id) => c.onlineRecords[id])
          .whereType<OnlineTrack>()
          .toList();
      Widget song(
        OnlineTrack t,
        List<OnlineTrack> queue, {
        VoidCallback? remove,
      }) => ListTile(
        contentPadding: EdgeInsets.zero,
        leading: const Icon(Icons.music_video_outlined),
        title: Text(t.title, maxLines: 2, overflow: TextOverflow.ellipsis),
        subtitle: Text(t.artist, maxLines: 1),
        onTap: () => openOnlinePlayer(context, c, t, tracks: queue),
        trailing: IconButton(
          tooltip: remove == null
              ? 'Rimuovi preferito'
              : 'Rimuovi dalla playlist',
          onPressed: remove ?? () => c.favoriteOnline(t),
          icon: const Icon(Icons.remove_circle_outline),
        ),
      );
      return Scaffold(
        appBar: AppBar(title: const Text('Il tuo YouTube')),
        body: AuraBackground(
          color: Theme.of(context).colorScheme.primary,
          child: ListView(
            padding: const EdgeInsets.all(24),
            children: [
              const SectionTitle('Brani del cuore'),
              if (favorites.isEmpty)
                const EmptyMessage(
                  icon: Icons.favorite_border,
                  title: 'La musica che vuoi ritrovare',
                  message: 'Salva i video dalla ricerca o dal player.',
                ),
              ...favorites.map((t) => song(t, favorites)),
              SectionTitle(
                'Playlist YouTube',
                action: 'Crea',
                onAction: () async {
                  final name = await askName(context);
                  if (name != null) c.createOnlinePlaylist(name);
                },
              ),
              ...c.onlinePlaylists.map((p) {
                final tracks = p.trackIds
                    .map((id) => c.onlineRecords[id])
                    .whereType<OnlineTrack>()
                    .toList();
                return ExpansionTile(
                  tilePadding: EdgeInsets.zero,
                  title: Text(p.name),
                  subtitle: Text('${tracks.length} video'),
                  children: [
                    Row(
                      children: [
                        TextButton(
                          onPressed: () async {
                            final name = await askName(
                              context,
                              initial: p.name,
                              title: 'Rinomina playlist',
                            );
                            if (name != null) c.renamePlaylist(p, name);
                          },
                          child: const Text('Rinomina'),
                        ),
                        TextButton(
                          onPressed: () async {
                            final remove = await showDialog<bool>(
                              context: context,
                              builder: (ctx) => AlertDialog(
                                title: const Text('Eliminare la playlist?'),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.pop(ctx, false),
                                    child: const Text('Annulla'),
                                  ),
                                  TextButton(
                                    onPressed: () => Navigator.pop(ctx, true),
                                    child: const Text('Elimina'),
                                  ),
                                ],
                              ),
                            );
                            if (remove == true) c.deleteOnlinePlaylist(p);
                          },
                          child: const Text('Elimina'),
                        ),
                      ],
                    ),
                    ...tracks.map(
                      (t) => song(
                        t,
                        tracks,
                        remove: () => c.removeFromPlaylist(p, t.id),
                      ),
                    ),
                  ],
                );
              }),
            ],
          ),
        ),
      );
    },
  );
}
