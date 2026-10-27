import '../../shared/models/music.dart';
import 'catalog_identity.dart';
import 'music_json_client.dart';

class CatalogMatch {
  const CatalogMatch(
    this.identity, {
    required this.score,
    required this.durationSeconds,
  });
  final CatalogIdentity identity;
  final int score, durationSeconds;
  String get artist => identity.artists.map((a) => a.name).join(', ');
}

abstract class MetadataCatalog {
  Future<List<CatalogMatch>> search(Track track);
}

String normalizeMusicText(String value) {
  const accents = 'àáâäãåèéêëìíîïòóôöõùúûüçñ';
  const plain = 'aaaaaaeeeeiiiiooooouuuucn';
  var s = value.toLowerCase();
  for (var i = 0; i < accents.length; i++) {
    s = s.replaceAll(accents[i], plain[i]);
  }
  return s
      .replaceAll(RegExp(r'[^\p{L}\p{N}]+', unicode: true), ' ')
      .trim()
      .replaceAll(RegExp(r'\s+'), ' ');
}

String cleanMusicTitle(String value) => value
    .replaceAll(
      RegExp(
        r'[\[(](?:official[^\])]*|video ufficiale[^\])]*|audio ufficiale[^\])]*|lyrics?|visuali[sz]er|hd|4k)[\])]',
        caseSensitive: false,
      ),
      '',
    )
    .replaceAll(RegExp(r'\s+'), ' ')
    .trim();
String cleanMusicArtist(String value) => value
    .replaceAll(
      RegExp(r'\s*(?:-\s*Topic|Official|VEVO)$', caseSensitive: false),
      '',
    )
    .trim();

/// Auto association is deliberately strict: edition/version words remain.
bool isConfidentCatalogMatch(Track track, CatalogMatch match) {
  if (match.score < 95 ||
      normalizeMusicText(track.title).isEmpty ||
      normalizeMusicText(track.artist).isEmpty) {
    return false;
  }
  var title = cleanMusicTitle(track.title);
  var artist = cleanMusicArtist(track.artist);
  final split = title.split(RegExp(r'\s[-–—]\s'));
  if (split.length == 2) {
    artist = split.first;
    title = split.last;
  }
  if (normalizeMusicText(title) != normalizeMusicText(match.identity.title)) {
    return false;
  }
  if (!match.identity.artists.any(
    (a) => normalizeMusicText(a.name) == normalizeMusicText(artist),
  )) {
    return false;
  }
  if (track.durationSeconds > 0 &&
      match.durationSeconds > 0 &&
      (track.durationSeconds - match.durationSeconds).abs() > 8) {
    return false;
  }
  return true;
}

class MusicBrainzCatalog implements MetadataCatalog {
  MusicBrainzCatalog(this.client);
  final MusicJsonClient client;
  final Map<String, List<CatalogMatch>> _cache = {};
  String _quoted(String value) =>
      '"${value.replaceAll('\\', '\\\\').replaceAll('"', '\\"')}"';
  @override
  Future<List<CatalogMatch>> search(Track track) async {
    var title = cleanMusicTitle(track.title);
    var artist = cleanMusicArtist(track.artist);
    final split = title.split(RegExp(r'\s[-–—]\s'));
    if (split.length == 2) {
      artist = split.first;
      title = split.last;
    }
    final key = '$title::$artist';
    if (_cache.containsKey(key)) return _cache[key]!;
    final uri = Uri.https('musicbrainz.org', '/ws/2/recording', {
      'query': 'recording:${_quoted(title)} AND artist:${_quoted(artist)}',
      'fmt': 'json',
      'limit': '15',
    });
    final data = await client.get(uri);
    final results = parseMusicBrainzRecordings(data);
    if (_cache.length >= 150) _cache.remove(_cache.keys.first);
    _cache[key] = results;
    return results;
  }
}

List<CatalogArtist> _artists(Object? raw) => (raw is List ? raw : [])
    .whereType<Map>()
    .where((e) => e['artist'] is Map)
    .map(
      (e) => CatalogArtist(
        id: e['artist']['id'] as String? ?? '',
        name: e['artist']['name'] as String? ?? e['name'] as String? ?? '',
      ),
    )
    .where((e) => e.id.isNotEmpty && e.name.isNotEmpty)
    .toList();

List<CatalogMatch> parseMusicBrainzRecordings(Object? data) {
  if (data is! Map || data['recordings'] is! List) return [];
  final output = <CatalogMatch>[];
  for (final record in (data['recordings'] as List).whereType<Map>()) {
    final id = record['id'] as String? ?? '';
    final artists = _artists(record['artist-credit']);
    if (id.isEmpty || artists.isEmpty) continue;
    final releases = (record['releases'] as List? ?? [])
        .whereType<Map>()
        .toList();
    int rank(Map r) {
      final group = r['release-group'] as Map? ?? {};
      final secondary = group['secondary-types'] as List? ?? [];
      return (r['status'] == 'Official' ? 0 : 10) +
          (secondary.isNotEmpty ? 20 : 0) +
          (group['primary-type'] == 'Album' ? 0 : 5);
    }

    releases.sort((a, b) {
      final compared = rank(a).compareTo(rank(b));
      return compared != 0
          ? compared
          : (a['date'] as String? ?? '9999').compareTo(
              b['date'] as String? ?? '9999',
            );
    });
    final release = releases.isEmpty ? <String, dynamic>{} : releases.first;
    final group = release['release-group'] as Map? ?? {};
    final albumArtists = _artists(release['artist-credit']);
    final albumArtist = albumArtists.isEmpty
        ? artists.first
        : albumArtists.first;
    output.add(
      CatalogMatch(
        CatalogIdentity(
          recordingId: id,
          title: record['title'] as String? ?? '',
          artists: artists,
          releaseId: release['id'] as String? ?? '',
          releaseGroupId: group['id'] as String? ?? '',
          album: group['title'] as String? ?? release['title'] as String? ?? '',
          albumArtistId: albumArtist.id,
          albumArtist: albumArtist.name,
        ),
        score: int.tryParse('${record['score']}') ?? 0,
        durationSeconds: ((record['length'] as num? ?? 0) / 1000).round(),
      ),
    );
  }
  return output;
}

/// Adds a documented factual-metadata fallback when MusicBrainz is unavailable.
/// Apple preview audio and promotional artwork are never requested or used.
class ResilientMetadataCatalog implements MetadataCatalog {
  ResilientMetadataCatalog(this.client)
    : _musicbrainz = MusicBrainzCatalog(client);
  final MusicJsonClient client;
  final MusicBrainzCatalog _musicbrainz;
  final Map<String, List<CatalogMatch>> _cache = {};
  @override
  Future<List<CatalogMatch>> search(Track track) async {
    final key = '${track.title}::${track.artist}';
    if (_cache.containsKey(key)) return _cache[key]!;
    try {
      final mb = await _musicbrainz.search(track);
      if (mb.isNotEmpty) {
        _remember(key, mb);
        return mb;
      }
    } catch (_) {
      /* An unavailable catalog must not disable association. */
    }
    final title = cleanMusicTitle(track.title);
    final data = await client.get(
      Uri.https('itunes.apple.com', '/search', {
        'term': '$title ${cleanMusicArtist(track.artist)}',
        'entity': 'song',
        'media': 'music',
        'country': 'IT',
        'limit': '50',
      }),
    );
    final results = parseAppleCatalog(data, track);
    _remember(key, results);
    return results;
  }

  void _remember(String key, List<CatalogMatch> matches) {
    if (_cache.length >= 150) _cache.remove(_cache.keys.first);
    _cache[key] = matches;
  }
}

List<CatalogMatch> parseAppleCatalog(Object? raw, Track query) {
  if (raw is! Map || raw['results'] is! List) return [];
  final output = <CatalogMatch>[];
  for (final row in (raw['results'] as List).whereType<Map>()) {
    if (row['kind'] != 'song' ||
        row['trackId'] == null ||
        row['artistId'] == null ||
        row['collectionId'] == null) {
      continue;
    }
    final artist = CatalogArtist(
      id: 'apple:${row['artistId']}',
      name: row['artistName'] as String? ?? '',
    );
    final identity = CatalogIdentity(
      recordingId: 'apple:${row['trackId']}',
      provider: 'Apple',
      catalogUrl: row['trackViewUrl'] as String? ?? '',
      title: row['trackName'] as String? ?? '',
      artists: [artist],
      releaseGroupId: 'apple:${row['collectionId']}',
      album: row['collectionName'] as String? ?? '',
      albumArtist: artist.name,
      albumArtistId: artist.id,
    );
    final candidate = CatalogMatch(
      identity,
      score: 100,
      durationSeconds: ((row['trackTimeMillis'] as num? ?? 0) / 1000).round(),
    );
    output.add(
      CatalogMatch(
        identity,
        score: isConfidentCatalogMatch(query, candidate) ? 100 : 70,
        durationSeconds: candidate.durationSeconds,
      ),
    );
  }
  output.sort((a, b) => b.score.compareTo(a.score));
  return output;
}
