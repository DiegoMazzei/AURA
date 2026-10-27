import '../catalog/music_json_client.dart';
import '../catalog/musicbrainz_catalog.dart';
import '../../shared/models/music.dart';

class LyricsCandidate {
  const LyricsCandidate({
    required this.id,
    required this.title,
    required this.artist,
    this.album = '',
    this.duration = 0,
    this.synced = '',
    this.plain = '',
    this.instrumental = false,
  });
  final int id, duration;
  final String title, artist, album, synced, plain;
  final bool instrumental;
  bool get synchronized => parseLrc(synced).isNotEmpty;
  String get sourceUrl => 'https://lrclib.net/api/get/$id';
}

abstract class LyricsProvider {
  Future<List<LyricsCandidate>> search(Track track);
}

String _lyricTitle(String value) => cleanMusicTitle(value)
    .replaceAll(
      RegExp(
        r'[\[(](?:feat\.?|ft\.?|featuring)\s+[^\])]+[\])]',
        caseSensitive: false,
      ),
      '',
    )
    .trim();
String _key(String value) =>
    normalizeMusicText(value.replaceAll(RegExp("['’]"), ''));
bool lyricsMatch(
  Track track,
  LyricsCandidate candidate, {
  bool requireTiming = true,
}) {
  final artists =
      track.catalogIdentity?.artists.map((a) => _key(a.name)).toSet() ??
      {_key(cleanMusicArtist(track.artist))};
  return !candidate.instrumental &&
      _key(_lyricTitle(track.title)) == _key(_lyricTitle(candidate.title)) &&
      (artists.contains(_key(candidate.artist)) ||
          _key(track.artist) == _key(candidate.artist)) &&
      (!requireTiming ||
          !candidate.synchronized ||
          track.durationSeconds <= 0 ||
          candidate.duration <= 0 ||
          (candidate.duration - track.durationSeconds).abs() <= 10);
}

class LrclibLyricsProvider implements LyricsProvider {
  LrclibLyricsProvider(this.client);
  final MusicJsonClient client;
  final Map<String, Future<List<LyricsCandidate>>> _pending = {};
  final Map<String, List<LyricsCandidate>> _cache = {};
  @override
  Future<List<LyricsCandidate>> search(Track track) {
    final key =
        '${track.artist}:${track.title}:${track.album}:${track.durationSeconds}';
    if (_cache.containsKey(key)) return Future.value(_cache[key]);
    return _pending.putIfAbsent(key, () async {
      try {
        final result = await _search(track);
        if (result.isNotEmpty) {
          if (_cache.length >= 100) _cache.remove(_cache.keys.first);
          _cache[key] = result;
        }
        return result;
      } finally {
        _pending.remove(key);
      }
    });
  }

  Future<List<LyricsCandidate>> _search(Track track) async {
    var title = _lyricTitle(track.title);
    var artist =
        track.catalogIdentity?.artists.firstOrNull?.name ??
        cleanMusicArtist(track.artist);
    if (track.catalogIdentity == null) {
      final split = title.split(RegExp(r'\s[-–—]\s'));
      if (split.length == 2) {
        artist = split.first;
        title = split.last;
      }
    }
    final queries = [
      (
        '/api/get',
        {
          'track_name': title,
          'artist_name': artist,
          if (track.album.isNotEmpty) 'album_name': track.album,
          if (track.durationSeconds > 0) 'duration': '${track.durationSeconds}',
        },
      ),
      ('/api/search', {'track_name': title, 'artist_name': artist}),
      ('/api/search', {'q': '$artist $title'}),
    ];
    final found = <int, LyricsCandidate>{};
    Object? failure;
    var succeeded = false;
    for (final (path, args) in queries) {
      try {
        final data = await client.get(Uri.https('lrclib.net', path, args));
        succeeded = true;
        for (final r in parseLyricsCandidates(data is Map ? [data] : data)) {
          found[r.id] = r;
        }
        if (found.values.any((r) => r.synchronized && lyricsMatch(track, r))) {
          break;
        }
      } catch (e) {
        failure = e;
      }
    }
    if (!succeeded && failure != null) throw failure;
    final result = found.values.toList()
      ..sort((a, b) {
        int rank(LyricsCandidate r) =>
            (lyricsMatch(track, r) ? 0 : 100) +
            (r.synchronized ? 0 : 20) +
            (track.durationSeconds > 0
                ? (r.duration - track.durationSeconds).abs().clamp(0, 15)
                : 0);
        return rank(a).compareTo(rank(b));
      });
    return result.take(20).toList();
  }
}

List<LyricsCandidate> parseLyricsCandidates(Object? data) =>
    (data is List ? data : [])
        .whereType<Map>()
        .map(
          (j) => LyricsCandidate(
            id: (j['id'] as num?)?.toInt() ?? 0,
            title: j['trackName'] as String? ?? '',
            artist: j['artistName'] as String? ?? '',
            album: j['albumName'] as String? ?? '',
            duration: (j['duration'] as num?)?.round() ?? 0,
            synced: j['syncedLyrics'] as String? ?? '',
            plain: j['plainLyrics'] as String? ?? '',
            instrumental: j['instrumental'] == true,
          ),
        )
        .where(
          (c) =>
              c.id > 0 &&
              (c.instrumental || c.synced.isNotEmpty || c.plain.isNotEmpty),
        )
        .toList();
