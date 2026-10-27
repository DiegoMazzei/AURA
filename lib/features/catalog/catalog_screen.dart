import 'dart:async';

import 'package:flutter/material.dart';

import '../../app/aura_controller.dart';
import '../../core/catalog/artist_directory.dart';
import '../../core/catalog/musicbrainz_catalog.dart';
import '../../shared/models/music.dart';
import '../player/player_screen.dart' show MiniPlayer;
import '../../core/design/aura_design.dart';
import '../youtube/online_search_screen.dart';
import '../youtube/online_track.dart';
import '../youtube/online_player_screen.dart' show openOnlinePlayer;

void openCatalogArtist(
  BuildContext context,
  AuraController c,
  DirectoryArtist artist,
) => Navigator.push(
  context,
  MaterialPageRoute<void>(
    builder: (_) => ArtistScreen(controller: c, artist: artist),
  ),
);
void openCatalogAlbum(
  BuildContext context,
  AuraController c,
  DirectoryAlbum album,
) => Navigator.push(
  context,
  MaterialPageRoute<void>(
    builder: (_) => AlbumScreen(controller: c, album: album),
  ),
);
Future<void> openCatalogSong(
  BuildContext context,
  AuraController c,
  DirectorySong song,
) async {
  final selected = await showModalBottomSheet<OnlineTrack>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (_) => _RecordingPicker(controller: c, song: song),
  );
  if (selected == null || !context.mounted) return;
  final native = c.nativeTrackFor(selected);
  c.applyCatalogIdentity(native, song.identity);
  await openOnlinePlayer(context, c, selected);
}

class _RecordingPicker extends StatefulWidget {
  const _RecordingPicker({required this.controller, required this.song});
  final AuraController controller;
  final DirectorySong song;
  @override
  State<_RecordingPicker> createState() => _RecordingPickerState();
}

class _RecordingPickerState extends State<_RecordingPicker> {
  late Future<List<OnlineTrack>> _results = _load();
  Future<List<OnlineTrack>> _load() async {
    final results = await widget.controller.catalog.search(
      '${widget.song.artist} ${widget.song.title}',
    );
    final exact = results
        .where(
          (t) => isConfidentCatalogMatch(
            Track(
              id: 'yt:${t.id}',
              title: t.title,
              artist: t.artist,
              source: t.id,
              isYoutube: true,
              durationSeconds: t.durationSeconds,
            ),
            CatalogMatch(
              widget.song.identity,
              score: 100,
              durationSeconds: widget.song.seconds,
            ),
          ),
        )
        .toList();
    // Do not silently pick between distinct equally plausible recordings.
    if (exact.length == 1 && mounted) {
      Navigator.pop(context, exact.single);
    }
    return results;
  }

  @override
  Widget build(BuildContext context) => SafeArea(
    child: SizedBox(
      height: MediaQuery.sizeOf(context).height * .70,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 0, 12, 12),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.song.title,
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        widget.song.artist,
                        style: TextStyle(color: context.muted),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  tooltip: 'Chiudi',
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
          ),
          Expanded(
            child: FutureBuilder<List<OnlineTrack>>(
              future: _results,
              builder: (context, snap) {
                if (snap.hasError) {
                  return _Failure(
                    message: 'Registrazioni non disponibili.',
                    onRetry: () => setState(() => _results = _load()),
                  );
                }
                if (!snap.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snap.data!.isEmpty) {
                  return const Center(
                    child: Text('Nessuna registrazione disponibile.'),
                  );
                }
                return ListView(
                  children: [
                    const Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                      child: Text('Scegli la versione che vuoi ascoltare.'),
                    ),
                    ...snap.data!.map(
                      (t) => ListTile(
                        leading: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.network(
                            t.thumbnail,
                            width: 48,
                            height: 48,
                            fit: BoxFit.cover,
                            errorBuilder: (_, _, _) => const SizedBox(
                              width: 48,
                              child: Icon(Icons.music_note),
                            ),
                          ),
                        ),
                        title: Text(
                          t.title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        subtitle: Text(t.artist),
                        onTap: () => Navigator.pop(context, t),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    ),
  );
}

class CatalogSearchScreen extends StatefulWidget {
  const CatalogSearchScreen({super.key, required this.controller});
  final AuraController controller;
  @override
  State<CatalogSearchScreen> createState() => _CatalogSearchScreenState();
}

class _CatalogSearchScreenState extends State<CatalogSearchScreen> {
  final _field = TextEditingController();
  Timer? _debounce;
  int _revision = 0, _tab = 0;
  DirectoryResults? _results;
  bool _loading = false;
  String? _error;
  void _changed(String text) {
    _debounce?.cancel();
    _revision++;
    setState(() {
      _results = null;
      _error = null;
      _loading = text.trim().isNotEmpty;
    });
    if (text.trim().isNotEmpty) {
      _debounce = Timer(const Duration(milliseconds: 600), _search);
    }
  }

  Future<void> _search() async {
    _debounce?.cancel();
    final query = _field.text.trim();
    if (query.isEmpty) return;
    final revision = ++_revision;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final results = await widget.controller.artistDirectory!.search(query);
      if (!mounted || revision != _revision) return;
      setState(() {
        _results = results;
        _loading = false;
      });
    } catch (_) {
      if (!mounted || revision != _revision) return;
      setState(() {
        _loading = false;
        _error = 'Il catalogo non risponde. Riprova tra poco.';
      });
    }
  }

  @override
  void dispose() {
    _revision++;
    _debounce?.cancel();
    _field.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = widget.controller;
    final r = _results;
    return ListView(
      padding: const EdgeInsets.fromLTRB(24, 18, 24, 172),
      children: [
        const Text(
          'Cerca',
          style: TextStyle(
            fontSize: 35,
            fontWeight: FontWeight.w700,
            letterSpacing: -1.2,
          ),
        ),
        const SizedBox(height: 22),
        TextField(
          controller: _field,
          onChanged: _changed,
          onSubmitted: (_) => _search(),
          textInputAction: TextInputAction.search,
          decoration: InputDecoration(
            hintText: 'Brani, artisti, album',
            prefixIcon: const Icon(Icons.search),
            suffixIcon: _field.text.isEmpty
                ? null
                : IconButton(
                    tooltip: 'Cancella',
                    onPressed: () {
                      _field.clear();
                      _changed('');
                    },
                    icon: const Icon(Icons.close),
                  ),
          ),
        ),
        const SizedBox(height: 18),
        _Categories(
          labels: const ['Tutto', 'Brani', 'Artisti', 'Album'],
          selected: _tab,
          onChanged: (v) => setState(() => _tab = v),
        ),
        const SizedBox(height: 20),
        if (_loading) const LinearProgressIndicator(minHeight: 2),
        if (_error != null) _Failure(message: _error!, onRetry: _search),
        if (!_loading && r == null && _error == null)
          Padding(
            padding: const EdgeInsets.only(top: 46),
            child: Text(
              'La musica parte\nda un nome.',
              style: TextStyle(
                fontSize: 34,
                height: 1.15,
                letterSpacing: -1,
                color: context.muted,
              ),
            ),
          ),
        if (r != null && !_loading) ...[
          if ((_tab == 0 || _tab == 2) && r.artists.isNotEmpty) ...[
            const SectionTitle('Artisti'),
            ...(_tab == 0 ? r.artists.take(3) : r.artists).map(
              (a) => ArtistRow(
                artist: a,
                onTap: () => openCatalogArtist(context, c, a),
              ),
            ),
          ],
          if ((_tab == 0 || _tab == 1) && r.songs.isNotEmpty) ...[
            const SectionTitle('Brani'),
            ...(_tab == 0 ? r.songs.take(6) : r.songs).map(
              (s) =>
                  SongRow(song: s, onTap: () => openCatalogSong(context, c, s)),
            ),
            if (_tab == 0 && r.songs.length > 6)
              TextButton(
                onPressed: () => setState(() => _tab = 1),
                child: const Text('Mostra tutti i brani'),
              ),
          ],
          if ((_tab == 0 || _tab == 3) && r.albums.isNotEmpty) ...[
            const SectionTitle('Album'),
            ...(_tab == 0 ? r.albums.take(5) : r.albums).map(
              (a) => AlbumRow(
                album: a,
                onTap: () => openCatalogAlbum(context, c, a),
              ),
            ),
          ],
          if ((_tab == 0 &&
                  r.artists.isEmpty &&
                  r.songs.isEmpty &&
                  r.albums.isEmpty) ||
              (_tab == 1 && r.songs.isEmpty) ||
              (_tab == 2 && r.artists.isEmpty) ||
              (_tab == 3 && r.albums.isEmpty))
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 30),
              child: Text('Nessun risultato in questa categoria.'),
            ),
          const SizedBox(height: 20),
          TextButton(
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute<void>(
                builder: (_) => Scaffold(
                  appBar: AppBar(title: const Text('Altre versioni')),
                  body: OnlineSearchScreen(
                    controller: c,
                    initialQuery: _field.text,
                    showLocalLink: false,
                  ),
                ),
              ),
            ),
            child: const Text('Cerca anche tra le altre versioni'),
          ),
        ],
      ],
    );
  }
}

class ArtistScreen extends StatefulWidget {
  const ArtistScreen({
    super.key,
    required this.controller,
    required this.artist,
  });
  final AuraController controller;
  final DirectoryArtist artist;
  @override
  State<ArtistScreen> createState() => _ArtistScreenState();
}

class _ArtistScreenState extends State<ArtistScreen> {
  late Future<List<DirectoryAlbum>> _albums = widget.controller.artistDirectory!
      .albums(widget.artist);
  late Future<DirectoryResults> _songs = widget.controller.artistDirectory!
      .search(widget.artist.name);
  int _tab = 0;
  @override
  Widget build(BuildContext context) => _CatalogScaffold(
    controller: widget.controller,
    title: 'Artista',
    body: ListView(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 40),
      children: [
        const SizedBox(height: 16),
        Text(
          widget.artist.name,
          style: const TextStyle(
            fontSize: 48,
            fontWeight: FontWeight.w700,
            height: 1.05,
            letterSpacing: -1.8,
          ),
        ),
        const SizedBox(height: 14),
        Text(
          widget.artist.genre.isEmpty ? 'Artista' : widget.artist.genre,
          style: TextStyle(color: context.muted, fontSize: 17),
        ),
        const SizedBox(height: 32),
        _Categories(
          labels: const ['Brani', 'Album', 'Feat.'],
          selected: _tab,
          onChanged: (v) => setState(() => _tab = v),
        ),
        const SizedBox(height: 24),
        if (_tab == 1)
          FutureBuilder<List<DirectoryAlbum>>(
            future: _albums,
            builder: (context, snap) {
              if (snap.hasError) {
                return _Failure(
                  message: 'Discografia non disponibile.',
                  onRetry: () => setState(
                    () => _albums = widget.controller.artistDirectory!.albums(
                      widget.artist,
                    ),
                  ),
                );
              }
              if (!snap.hasData) {
                return const LinearProgressIndicator(minHeight: 2);
              }
              final albums = snap.data!;
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Discografia · ${albums.length} uscite',
                    style: TextStyle(color: context.muted),
                  ),
                  const SizedBox(height: 14),
                  ...albums.map(
                    (a) => AlbumRow(
                      album: a,
                      onTap: () =>
                          openCatalogAlbum(context, widget.controller, a),
                    ),
                  ),
                  if (albums.isEmpty)
                    const Text('Nessuna uscita disponibile nel catalogo.'),
                  if (albums.length >= 200)
                    const Text('Mostrate le prime 200 uscite disponibili.'),
                ],
              );
            },
          )
        else
          FutureBuilder<DirectoryResults>(
            future: _songs,
            builder: (context, snap) {
              if (snap.hasError) {
                return _Failure(
                  message: 'Brani non disponibili.',
                  onRetry: () => setState(
                    () => _songs = widget.controller.artistDirectory!.search(
                      widget.artist.name,
                    ),
                  ),
                );
              }
              if (!snap.hasData) {
                return const LinearProgressIndicator(minHeight: 2);
              }
              final songs = artistSongs(
                snap.data!.songs,
                widget.artist,
                collaborationsOnly: _tab == 2,
              );
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _tab == 2
                        ? 'Collaborazioni nel catalogo'
                        : 'Brani in evidenza',
                    style: TextStyle(color: context.muted),
                  ),
                  const SizedBox(height: 14),
                  ...songs.map(
                    (s) => SongRow(
                      song: s,
                      onTap: () =>
                          openCatalogSong(context, widget.controller, s),
                    ),
                  ),
                  if (songs.isEmpty)
                    const Text('Nessun brano disponibile in questa sezione.'),
                ],
              );
            },
          ),
      ],
    ),
  );
}

List<DirectorySong> artistSongs(
  List<DirectorySong> songs,
  DirectoryArtist artist, {
  bool collaborationsOnly = false,
}) {
  final name = normalizeMusicText(artist.name);
  return songs.where((s) {
    final credit = normalizeMusicText(s.artist);
    final title = normalizeMusicText(s.title);
    final related =
        s.artistId == artist.id ||
        (' $credit ').contains(' $name ') ||
        (' $title ').contains(' $name ');
    final collaboration =
        (credit != name && (' $credit ').contains(' $name ')) ||
        RegExp(
          r'\b(?:feat|featuring|ft)\b',
          caseSensitive: false,
        ).hasMatch(s.title);
    return related && (!collaborationsOnly || collaboration);
  }).toList();
}

class AlbumScreen extends StatefulWidget {
  const AlbumScreen({super.key, required this.controller, required this.album});
  final AuraController controller;
  final DirectoryAlbum album;
  @override
  State<AlbumScreen> createState() => _AlbumScreenState();
}

class _AlbumScreenState extends State<AlbumScreen> {
  late Future<List<DirectorySong>> _songs = widget.controller.artistDirectory!
      .songs(widget.album);
  @override
  Widget build(BuildContext context) => _CatalogScaffold(
    controller: widget.controller,
    title: 'Album',
    body: ListView(
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 40),
      children: [
        Text(
          widget.album.title,
          style: const TextStyle(
            fontSize: 36,
            height: 1.1,
            letterSpacing: -1,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          '${widget.album.artist} · ${widget.album.year == 0 ? '' : widget.album.year}',
          style: TextStyle(fontSize: 17, color: context.muted),
        ),
        const SizedBox(height: 30),
        FutureBuilder<List<DirectorySong>>(
          future: _songs,
          builder: (context, snap) {
            if (snap.hasError) {
              return _Failure(
                message: 'Scaletta non disponibile.',
                onRetry: () => setState(
                  () => _songs = widget.controller.artistDirectory!.songs(
                    widget.album,
                  ),
                ),
              );
            }
            if (!snap.hasData) {
              return const LinearProgressIndicator(minHeight: 2);
            }
            return Column(
              children: [
                if (snap.data!.isEmpty)
                  const Text('Nessun brano disponibile nel catalogo.'),
                ...snap.data!.map(
                  (s) => SongRow(
                    song: s,
                    numbered: true,
                    onTap: () => openCatalogSong(context, widget.controller, s),
                  ),
                ),
              ],
            );
          },
        ),
      ],
    ),
  );
}

class ArtistRow extends StatelessWidget {
  const ArtistRow({super.key, required this.artist, required this.onTap});
  final DirectoryArtist artist;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => ListTile(
    contentPadding: const EdgeInsets.symmetric(vertical: 8),
    leading: CircleAvatar(
      radius: 27,
      backgroundColor: context.ink.withValues(alpha: .06),
      foregroundColor: context.ink,
      child: Text(
        artist.name.isEmpty ? '♪' : artist.name.characters.first,
        style: const TextStyle(fontSize: 23, fontWeight: FontWeight.w600),
      ),
    ),
    title: Text(
      artist.name,
      style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w600),
    ),
    subtitle: Text(artist.genre.isEmpty ? 'Artista' : artist.genre),
    trailing: const Icon(Icons.chevron_right, size: 20),
    onTap: onTap,
  );
}

class AlbumRow extends StatelessWidget {
  const AlbumRow({super.key, required this.album, required this.onTap});
  final DirectoryAlbum album;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => ListTile(
    contentPadding: const EdgeInsets.symmetric(vertical: 8),
    leading: Container(
      width: 54,
      height: 54,
      decoration: BoxDecoration(
        color: context.ink.withValues(alpha: .05),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(Icons.album_outlined, color: context.muted, size: 30),
    ),
    title: Text(
      album.title,
      style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w500),
    ),
    subtitle: Text(
      '${album.artist}${album.year > 0 ? ' · ${album.year}' : ''}',
    ),
    trailing: const Icon(Icons.chevron_right, size: 20),
    onTap: onTap,
  );
}

class SongRow extends StatelessWidget {
  const SongRow({
    super.key,
    required this.song,
    required this.onTap,
    this.numbered = false,
  });
  final DirectorySong song;
  final VoidCallback onTap;
  final bool numbered;
  @override
  Widget build(BuildContext context) => ListTile(
    contentPadding: const EdgeInsets.symmetric(vertical: 3),
    leading: SizedBox(
      width: 28,
      child: Text(
        numbered ? '${song.number}' : '♪',
        style: TextStyle(color: context.muted, fontSize: 17),
        textAlign: TextAlign.center,
      ),
    ),
    title: Text(
      song.title,
      style: const TextStyle(fontSize: 17),
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
    ),
    subtitle: Text(
      numbered ? song.artist : '${song.artist} · ${song.album}',
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    ),
    trailing: const Icon(Icons.play_arrow_rounded, size: 23),
    onTap: onTap,
  );
}

class _Categories extends StatelessWidget {
  const _Categories({
    required this.labels,
    required this.selected,
    required this.onChanged,
  });
  final List<String> labels;
  final int selected;
  final ValueChanged<int> onChanged;
  @override
  Widget build(BuildContext context) => SingleChildScrollView(
    scrollDirection: Axis.horizontal,
    child: Row(
      children: [
        for (var i = 0; i < labels.length; i++)
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ChoiceChip(
              label: Text(labels[i]),
              selected: selected == i,
              onSelected: (_) => onChanged(i),
            ),
          ),
      ],
    ),
  );
}

class _Failure extends StatelessWidget {
  const _Failure({required this.message, required this.onRetry});
  final String message;
  final VoidCallback onRetry;
  @override
  Widget build(BuildContext context) => Column(
    children: [
      Text(message),
      TextButton(onPressed: onRetry, child: const Text('Riprova')),
    ],
  );
}

class _CatalogScaffold extends StatelessWidget {
  const _CatalogScaffold({
    required this.controller,
    required this.title,
    required this.body,
  });
  final AuraController controller;
  final String title;
  final Widget body;
  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: controller,
    builder: (_, _) => Scaffold(
      appBar: AppBar(title: Text(title)),
      body: body,
      bottomNavigationBar: controller.hasCurrent
          ? SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                child: MiniPlayer(controller: controller),
              ),
            )
          : null,
    ),
  );
}
