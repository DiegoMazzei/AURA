import 'package:flutter/material.dart';

import '../../app/aura_controller.dart';
import '../../core/design/aura_design.dart';
import '../../shared/models/music.dart';
import 'track_tile.dart';
import '../spotify_import/import_screen.dart';
import '../player/player_screen.dart';
import 'library_groups.dart';

class LibraryScreen extends StatefulWidget {
  const LibraryScreen({super.key, required this.controller});
  final AuraController controller;
  @override
  State<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends State<LibraryScreen> {
  String _view = 'Brani';
  String _query = '';
  @override
  Widget build(BuildContext context) {
    final c = widget.controller;
    final library = c.libraryTracks
        .where(
          (t) => '${t.title} ${t.artist} ${t.album}'.toLowerCase().contains(
            _query.toLowerCase(),
          ),
        )
        .toList();
    final groups = _view == 'Artisti'
        ? groupByArtist(library)
        : groupByAlbum(library);
    return ListView(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 184),
      children: [
        Row(
          children: [
            const Expanded(
              child: Text(
                'Libreria',
                style: TextStyle(
                  fontSize: 30,
                  fontWeight: FontWeight.w600,
                  letterSpacing: -1,
                ),
              ),
            ),
            GlassIcon(
              icon: Icons.add_rounded,
              label: 'Importa file audio',
              onPressed: c.importing ? null : c.importAudio,
            ),
          ],
        ),
        const SizedBox(height: 9),
        Text(
          'La musica che hai scelto.',
          style: TextStyle(color: context.muted),
        ),
        const SizedBox(height: 22),
        AuraGlassSurface(
          child: ListTile(
            leading: const Icon(Icons.favorite_rounded, color: auraPink),
            title: const Text('Brani del cuore'),
            subtitle: Text('${c.favorites.length} preferiti'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute<void>(
                builder: (_) => _Favorites(controller: c),
              ),
            ),
          ),
        ),
        SectionTitle(
          'Libreria',
          action: 'Crea',
          onAction: () async {
            final name = await askName(context);
            if (name != null) {
              c.createPlaylist(name);
              setState(() => _view = 'Playlist');
            }
          },
        ),
        TextField(
          onChanged: (value) => setState(() => _query = value),
          decoration: const InputDecoration(
            hintText: 'Cerca nella libreria',
            prefixIcon: Icon(Icons.search),
          ),
        ),
        const SizedBox(height: 14),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: ['Brani', 'Artisti', 'Album', 'Playlist']
                .map(
                  (name) => Padding(
                    padding: const EdgeInsets.only(right: 7),
                    child: ChoiceChip(
                      label: Text(name),
                      selected: _view == name,
                      onSelected: (_) => setState(() => _view = name),
                    ),
                  ),
                )
                .toList(),
          ),
        ),
        if (c.metadataCatalog != null) ...[
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              onPressed: c.updatingCatalog ? null : c.enrichLibraryMetadata,
              icon: c.updatingCatalog
                  ? const SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(strokeWidth: 1.5),
                    )
                  : const Icon(Icons.auto_awesome_outlined, size: 16),
              label: Text(
                c.updatingCatalog
                    ? '${c.catalogDone} / ${c.catalogTotal}'
                    : 'Completa artisti e album',
              ),
            ),
          ),
          if (c.catalogMessage != null)
            Text(
              c.catalogMessage!,
              style: TextStyle(color: context.muted, fontSize: 12),
            ),
        ],
        const SizedBox(height: 15),
        if (_view == 'Brani') ...[
          if (library.isEmpty)
            const EmptyMessage(
              icon: Icons.search_off_rounded,
              title: 'Nessun risultato',
              message: 'Prova con un altro titolo, artista o album.',
            ),
          if (c.importing) const LinearProgressIndicator(),
          ...library.map(
            (t) => TrackTile(
              track: t,
              controller: c,
              onTap: () => c.playTrack(t, contextTracks: library),
            ),
          ),
        ],
        if (_view == 'Artisti' || _view == 'Album') ...[
          ...groups.map(
            (group) => ListTile(
              contentPadding: const EdgeInsets.symmetric(vertical: 4),
              leading: CosmicCover(
                color: Color(group.tracks.first.color),
                imageUrl: group.tracks.first.artworkUrl,
                size: 54,
                radius: _view == 'Artisti' ? 27 : 13,
              ),
              title: Text(group.name),
              subtitle: Text(
                _view == 'Artisti'
                    ? group.subtitle
                    : '${group.subtitle} · ${group.tracks.length} brani',
              ),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute<void>(
                  builder: (_) =>
                      _MusicGroupScreen(controller: c, group: group),
                ),
              ),
            ),
          ),
        ],
        if (_view == 'Playlist') ...[
          if (c.playlists.isEmpty)
            const EmptyMessage(
              icon: Icons.queue_music,
              title: 'Il tuo prossimo viaggio',
              message: 'Tocca Crea per aggiungere la tua prima playlist.',
            ),
          ...c.playlists.map(
            (p) => ListTile(
              contentPadding: const EdgeInsets.symmetric(vertical: 4),
              leading: const Icon(Icons.queue_music),
              title: Text(p.name),
              subtitle: Text('${p.trackIds.length} brani'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute<void>(
                  builder: (_) => PlaylistScreen(controller: c, playlist: p),
                ),
              ),
            ),
          ),
        ],
        const SizedBox(height: 20),
        ListTile(
          contentPadding: EdgeInsets.zero,
          leading: const Icon(Icons.cloud_download_outlined),
          title: const Text('Importa le tue playlist'),
          subtitle: Text(
            '${c.importedCollections.length} raccolte da JSON o CSV',
          ),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute<void>(
              builder: (_) => ImportScreen(controller: c),
            ),
          ),
        ),
        Text(
          'La tua raccolta, ordinata per chi la crea.',
          style: TextStyle(color: context.muted, fontSize: 12, height: 1.5),
        ),
      ],
    );
  }
}

class _MusicGroupScreen extends StatelessWidget {
  const _MusicGroupScreen({required this.controller, required this.group});
  final AuraController controller;
  final MusicGroup group;
  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: controller,
    builder: (_, _) {
      final ids = group.tracks.map((t) => t.id).toSet();
      final tracks = controller.libraryTracks
          .where((t) => ids.contains(t.id))
          .toList();
      return Scaffold(
        appBar: AppBar(title: Text(group.name)),
        bottomNavigationBar: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: MiniPlayer(controller: controller),
          ),
        ),
        body: AuraBackground(
          child: ListView(
            padding: const EdgeInsets.all(24),
            children: [
              if (group.unknownAlbum)
                Padding(
                  padding: const EdgeInsets.only(bottom: 20),
                  child: Text(
                    'Per questi brani il titolo dell’album non è disponibile. Puoi aggiungerlo da Modifica informazioni.',
                    style: TextStyle(color: context.muted),
                  ),
                ),
              ...tracks.map(
                (t) => TrackTile(
                  track: t,
                  controller: controller,
                  onTap: () => controller.playTrack(t, contextTracks: tracks),
                ),
              ),
            ],
          ),
        ),
      );
    },
  );
}

class _Favorites extends StatelessWidget {
  const _Favorites({required this.controller});
  final AuraController controller;
  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: controller,
    builder: (ctx, _) {
      final tracks = controller.tracks
          .where((t) => controller.favorites.contains(t.id))
          .toList();
      return Scaffold(
        appBar: AppBar(title: const Text('Brani del cuore')),
        bottomNavigationBar: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: MiniPlayer(controller: controller),
          ),
        ),
        body: AuraBackground(
          color: auraPink,
          child: ListView(
            padding: const EdgeInsets.all(24),
            children: [
              if (tracks.isEmpty)
                const EmptyMessage(
                  icon: Icons.favorite_border,
                  title: 'Il tuo prossimo colpo di fulmine',
                  message: 'Tocca il cuore nel player per ritrovare qui i tuoi brani.',
                ),
              ...tracks.map(
                (t) => TrackTile(
                  track: t,
                  controller: controller,
                  onTap: () => controller.playTrack(t, contextTracks: tracks),
                ),
              ),
            ],
          ),
        ),
      );
    },
  );
}

class PlaylistScreen extends StatelessWidget {
  const PlaylistScreen({
    super.key,
    required this.controller,
    required this.playlist,
  });
  final AuraController controller;
  final AuraPlaylist playlist;
  Future<void> _add(BuildContext context) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (ctx) => SafeArea(
        child: SizedBox(
          height: MediaQuery.sizeOf(ctx).height * .65,
          child: ListenableBuilder(
            listenable: controller,
            builder: (_, _) => ListView(
              padding: const EdgeInsets.all(24),
              children: [
                const Text(
                  'Scegli i brani',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.w600),
                ),
                ...controller.tracks.map(
                  (t) => CheckboxListTile(
                    title: Text(t.title),
                    subtitle: Text(t.artist),
                    value: playlist.trackIds.contains(t.id),
                    onChanged: (value) {
                      if (value == true) {
                        controller.addToPlaylist(playlist, t.id);
                      } else {
                        controller.removeFromPlaylist(playlist, t.id);
                      }
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: controller,
    builder: (ctx, _) {
      final tracks = controller.tracksFor(playlist);
      return Scaffold(
        appBar: AppBar(
          title: Text(playlist.name),
          actions: [
            PopupMenuButton<String>(
              tooltip: 'Opzioni playlist',
              onSelected: (value) async {
                if (value == 'rename') {
                  final name = await askName(
                    context,
                    initial: playlist.name,
                    title: 'Rinomina playlist',
                  );
                  if (name != null) controller.renamePlaylist(playlist, name);
                }
                if (value == 'delete' && context.mounted) {
                  final confirmed = await showDialog<bool>(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      title: const Text('Eliminare la playlist?'),
                      content: const Text(
                        'I brani resteranno nella tua libreria.',
                      ),
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
                  if (confirmed == true && context.mounted) {
                    controller.deletePlaylist(playlist);
                    Navigator.pop(context);
                  }
                }
              },
              itemBuilder: (_) => [
                const PopupMenuItem(value: 'rename', child: Text('Rinomina')),
                const PopupMenuItem(
                  value: 'delete',
                  child: Text('Elimina playlist'),
                ),
              ],
            ),
          ],
        ),
        body: AuraBackground(
          color: auraViolet,
          child: ReorderableListView(
            padding: const EdgeInsets.fromLTRB(24, 10, 24, 40),
            header: Column(
              children: [
                CosmicCover(
                  color: auraViolet,
                  size: 190,
                  title: playlist.name,
                  radius: 30,
                ),
                const SizedBox(height: 22),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    FilledButton.icon(
                      onPressed: tracks.isEmpty
                          ? null
                          : () => controller.playTrack(
                              tracks.first,
                              contextTracks: tracks,
                            ),
                      icon: const Icon(Icons.play_arrow_rounded),
                      label: const Text('Riproduci'),
                    ),
                    const SizedBox(width: 12),
                    OutlinedButton.icon(
                      onPressed: () => _add(context),
                      icon: const Icon(Icons.add),
                      label: const Text('Brani'),
                    ),
                  ],
                ),
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Text(
                    tracks.isEmpty
                        ? 'Aggiungi i tuoi primi brani.'
                        : 'Tieni premuto un brano per riordinarlo.',
                    style: TextStyle(color: context.muted, fontSize: 12),
                  ),
                ),
              ],
            ),
            onReorderItem: (from, to) =>
                controller.reorderPlaylist(playlist, from, to),
            children: [
              for (final t in tracks)
                TrackTile(
                  key: ValueKey(t.id),
                  track: t,
                  controller: controller,
                  onTap: () => controller.playTrack(t, contextTracks: tracks),
                  trailing: IconButton(
                    tooltip: 'Rimuovi dalla playlist',
                    onPressed: () =>
                        controller.removeFromPlaylist(playlist, t.id),
                    icon: const Icon(Icons.remove_circle_outline),
                  ),
                ),
            ],
          ),
        ),
      );
    },
  );
}
