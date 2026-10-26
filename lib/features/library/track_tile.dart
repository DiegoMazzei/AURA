import 'package:flutter/material.dart';

import '../../app/aura_controller.dart';
import '../../core/design/aura_design.dart';
import '../../shared/models/music.dart';

class TrackTile extends StatelessWidget {
  const TrackTile({
    super.key,
    required this.track,
    required this.controller,
    this.onTap,
    this.trailing,
  });
  final Track track;
  final AuraController controller;
  final VoidCallback? onTap;
  final Widget? trailing;
  @override
  Widget build(BuildContext context) => ListTile(
    contentPadding: const EdgeInsets.symmetric(horizontal: 0, vertical: 3),
    leading: CosmicCover(
      color: Color(track.color),
      imageUrl: track.artworkUrl,
      size: 50,
      radius: 12,
    ),
    title: Text(
      track.title,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: TextStyle(
        fontSize: 15,
        fontWeight: FontWeight.w500,
        color: controller.currentId == track.id && controller.audio.playing
            ? Theme.of(context).colorScheme.primary
            : null,
      ),
    ),
    subtitle: Text(
      '${track.artist}${track.isAsset ? ' · Originale demo' : ''}',
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: TextStyle(fontSize: 12, color: context.muted),
    ),
    onTap: onTap ?? () => controller.playTrack(track),
    trailing:
        trailing ??
        PopupMenuButton<String>(
          tooltip: 'Opzioni ${track.title}',
          icon: const Icon(Icons.more_horiz),
          onSelected: (value) {
            if (value == 'favorite') controller.toggleFavorite(track.id);
            if (value == 'queue') controller.enqueue(track);
            if (value == 'metadata') {
              editTrackMetadata(context, controller, track);
            }
            if (value == 'playlist') addToPlaylist(context, controller, track);
          },
          itemBuilder: (_) => [
            PopupMenuItem(
              value: 'favorite',
              child: Text(
                controller.favorites.contains(track.id)
                    ? 'Rimuovi dai preferiti'
                    : 'Aggiungi ai preferiti',
              ),
            ),
            const PopupMenuItem(
              value: 'metadata',
              child: Text('Modifica informazioni'),
            ),
            const PopupMenuItem(
              value: 'queue',
              child: Text('Aggiungi alla coda'),
            ),
            const PopupMenuItem(
              value: 'playlist',
              child: Text('Aggiungi a una playlist'),
            ),
          ],
        ),
  );
}

Future<String?> askName(
  BuildContext context, {
  String? initial,
  String title = 'Nuova playlist',
}) async {
  final field = TextEditingController(text: initial);
  final result = await showDialog<String>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(title),
      content: TextField(
        controller: field,
        autofocus: true,
        maxLength: 70,
        textCapitalization: TextCapitalization.sentences,
        decoration: const InputDecoration(labelText: 'Nome della playlist'),
        onSubmitted: (v) {
          if (v.trim().isNotEmpty) Navigator.pop(ctx, v.trim());
        },
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx),
          child: const Text('Annulla'),
        ),
        FilledButton(
          onPressed: () {
            if (field.text.trim().isNotEmpty) {
              Navigator.pop(ctx, field.text.trim());
            }
          },
          child: const Text('Salva'),
        ),
      ],
    ),
  );
  // The dialog route may still be animating its exit while it owns the field.
  Future<void>.delayed(const Duration(seconds: 1), field.dispose);
  return result;
}

Future<void> addToPlaylist(
  BuildContext context,
  AuraController controller,
  Track track,
) async {
  await showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    builder: (ctx) => SafeArea(
      child: ListView(
        shrinkWrap: true,
        children: [
          const Padding(
            padding: EdgeInsets.all(20),
            child: Text(
              'Aggiungi a una playlist',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.w600),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.add),
            title: const Text('Nuova playlist'),
            onTap: () async {
              final name = await askName(ctx);
              if (name != null) {
                controller.addToPlaylist(
                  controller.createPlaylist(name),
                  track.id,
                );
              }
              if (ctx.mounted && name != null) Navigator.pop(ctx);
            },
          ),
          ...controller.playlists.map(
            (p) => ListTile(
              leading: const Icon(Icons.queue_music),
              title: Text(p.name),
              subtitle: Text('${p.trackIds.length} brani'),
              onTap: () {
                controller.addToPlaylist(p, track.id);
                Navigator.pop(ctx);
              },
            ),
          ),
        ],
      ),
    ),
  );
}

void editTrackMetadata(
  BuildContext context,
  AuraController controller,
  Track track,
) => showDialog<void>(
  context: context,
  builder: (_) => _TrackMetadataDialog(controller: controller, track: track),
);

class _TrackMetadataDialog extends StatefulWidget {
  const _TrackMetadataDialog({required this.controller, required this.track});
  final AuraController controller;
  final Track track;
  @override
  State<_TrackMetadataDialog> createState() => _TrackMetadataDialogState();
}

class _TrackMetadataDialogState extends State<_TrackMetadataDialog> {
  late final _title = TextEditingController(text: widget.track.title);
  late final _artist = TextEditingController(text: widget.track.artist);
  late final _album = TextEditingController(text: widget.track.album);
  @override
  void dispose() {
    _title.dispose();
    _artist.dispose();
    _album.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: const Text('Informazioni del brano'),
    content: SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _title,
            decoration: const InputDecoration(labelText: 'Titolo'),
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _artist,
            decoration: const InputDecoration(labelText: 'Artista'),
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _album,
            decoration: const InputDecoration(labelText: 'Album (se noto)'),
          ),
        ],
      ),
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: const Text('Annulla'),
      ),
      FilledButton(
        onPressed: _title.text.trim().isEmpty || _artist.text.trim().isEmpty
            ? null
            : () {
                widget.controller.updateTrackMetadata(
                  widget.track,
                  title: _title.text,
                  artist: _artist.text,
                  album: _album.text,
                );
                Navigator.pop(context);
              },
        child: const Text('Salva'),
      ),
    ],
  );
}
