import '../../shared/models/music.dart';

class MusicGroup {
  MusicGroup({
    required this.name,
    required this.subtitle,
    required this.tracks,
    this.unknownAlbum = false,
  });
  final String name, subtitle;
  final List<Track> tracks;
  final bool unknownAlbum;
}

String _normalized(String value) =>
    value.trim().toLowerCase().replaceAll(RegExp(r'\s+'), ' ');
List<MusicGroup> groupByArtist(Iterable<Track> tracks) {
  final groups = <String, List<Track>>{};
  final names = <String, String>{};
  for (final t in tracks) {
    final credits = t.catalogIdentity?.artists;
    if (credits != null && credits.isNotEmpty) {
      for (final a in credits) {
        final key = 'mb:${a.id}';
        names[key] = a.name;
        (groups[key] ??= []).add(t);
      }
    } else {
      final key = 'name:${_normalized(t.artist)}';
      names[key] = t.artist;
      (groups[key] ??= []).add(t);
    }
  }
  return groups.entries
      .map(
        (e) => MusicGroup(
          name: names[e.key]!,
          subtitle:
              '${e.value.length} ${e.value.length == 1 ? 'brano' : 'brani'}',
          tracks: e.value,
        ),
      )
      .toList()
    ..sort((a, b) => _normalized(a.name).compareTo(_normalized(b.name)));
}

List<MusicGroup> groupByAlbum(Iterable<Track> tracks) {
  final groups = <String, List<Track>>{};
  for (final t in tracks) {
    final identity = t.catalogIdentity;
    final key = identity?.releaseGroupId.isNotEmpty == true
        ? 'mb:${identity!.releaseGroupId}'
        : '${_normalized(identity?.albumArtist ?? t.artist)}::${_normalized(t.album)}';
    (groups[key] ??= []).add(t);
  }
  return groups.values
      .map(
        (list) => MusicGroup(
          name: list.first.album.trim().isEmpty
              ? 'Album da completare'
              : list.first.album,
          subtitle: list.first.catalogIdentity?.albumArtist.isNotEmpty == true
              ? list.first.catalogIdentity!.albumArtist
              : list.first.artist,
          tracks: list,
          unknownAlbum: list.first.album.trim().isEmpty,
        ),
      )
      .toList()
    ..sort(
      (a, b) => '${a.unknownAlbum}:${_normalized(a.name)}'.compareTo(
        '${b.unknownAlbum}:${_normalized(b.name)}',
      ),
    );
}
