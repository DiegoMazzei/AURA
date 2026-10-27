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

class LrclibLyricsProvider implements LyricsProvider {
  LrclibLyricsProvider(this.client);
  final MusicJsonClient client;
  @override
  Future<List<LyricsCandidate>> search(Track track) async {
    final data = await client.get(
      Uri.https('lrclib.net', '/api/search', {
        'track_name': cleanMusicTitle(track.title),
        'artist_name':
            track.catalogIdentity?.artists.firstOrNull?.name ??
            cleanMusicArtist(track.artist),
      }),
    );
    final results = parseLyricsCandidates(data);
    results.sort((a, b) {
      int rank(LyricsCandidate c) =>
          (normalizeMusicText(c.title) == normalizeMusicText(track.title)
              ? 0
              : 40) +
          (normalizeMusicText(c.artist) == normalizeMusicText(track.artist)
              ? 0
              : 20) +
          (c.synchronized ? 0 : 10) +
          (track.durationSeconds > 0
              ? (c.duration - track.durationSeconds).abs().clamp(0, 30)
              : 0);
      return rank(a).compareTo(rank(b));
    });
    return results.take(20).toList();
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
