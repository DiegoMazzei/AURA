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
  for (final t in tracks) {
    (groups[_normalized(t.artist)] ??= []).add(t);
  }
  return groups.values
      .map(
        (list) => MusicGroup(
          name: list.first.artist,
          subtitle: '${list.length} brani',
          tracks: list,
        ),
      )
      .toList()
    ..sort((a, b) => _normalized(a.name).compareTo(_normalized(b.name)));
}

List<MusicGroup> groupByAlbum(Iterable<Track> tracks) {
  final groups = <String, List<Track>>{};
  for (final t in tracks) {
    final key = '${_normalized(t.artist)}::${_normalized(t.album)}';
    (groups[key] ??= []).add(t);
  }
  return groups.values
      .map(
        (list) => MusicGroup(
          name: list.first.album.trim().isEmpty
              ? 'Album da completare'
              : list.first.album,
          subtitle: list.first.artist,
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
