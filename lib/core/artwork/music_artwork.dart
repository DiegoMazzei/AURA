import 'dart:async';

import '../catalog/music_json_client.dart';
import '../catalog/musicbrainz_catalog.dart';

abstract class ArtworkRepository {
  Future<String?> artist(String name);
  Future<String?> album(String artist, String title);
  String? cachedAlbum(String artist, String title) => null;
  Map<String, String> exportCache() => {};
  void restoreCache(Map<String, dynamic> data) {}
}

class MusicArtwork implements ArtworkRepository {
  MusicArtwork(this.client);
  final MusicJsonClient client;
  final Map<String, String> _cache = {};
  final Map<String, Future<String?>> _pending = {};
  final Map<String, DateTime> _misses = {};
  final Map<String, Future<List<Map>>> _albums = {};
  List<Map> _rows(Object? data, String key) => data is Map && data[key] is List
      ? (data[key] as List).whereType<Map>().toList()
      : [];
  String? _url(Object? value) {
    if (value is! String) return null;
    final uri = Uri.tryParse(value);
    if (uri?.scheme != 'https' ||
        uri!.host.isEmpty ||
        value.contains('/artist//')) {
      return null;
    }
    return value;
  }

  Future<String?> _memo(String key, Future<String?> Function() lookup) {
    if (_cache.containsKey(key)) return Future.value(_cache[key]);
    if (_misses[key]?.isAfter(DateTime.now()) == true) {
      return Future.value(null);
    }
    return _pending.putIfAbsent(key, () async {
      final result = await lookup();
      if (result != null) {
        if (_cache.length >= 500) _cache.remove(_cache.keys.first);
        _cache[key] = result;
      }
      if (result == null) {
        _misses[key] = DateTime.now().add(const Duration(minutes: 1));
      }
      _pending.remove(key);
      return result;
    });
  }

  // Independent providers race; a slow/missing photo never delays a valid one.
  // MusicJsonClient still enforces each provider's own request interval.
  Future<String?> _first(List<Future<String?>> sources) {
    final result = Completer<String?>();
    var remaining = sources.length;
    for (final source in sources) {
      source
          .then((url) {
            if (url != null && !result.isCompleted) result.complete(url);
          }, onError: (Object _) {})
          .whenComplete(() {
            remaining--;
            if (remaining == 0 && !result.isCompleted) result.complete(null);
          });
    }
    return result.future;
  }

  @override
  Future<String?> artist(String name) => _memo(
    'artist:${normalizeMusicText(name)}',
    () => _first([_artistAudioDb(name), _artistDeezer(name)]),
  );

  Future<String?> _artistAudioDb(String name) async {
    final data = await client.get(
      Uri.https('www.theaudiodb.com', '/api/v1/json/123/search.php', {
        's': name,
      }),
    );
    for (final row in _rows(data, 'artists')) {
      if (normalizeMusicText(row['strArtist'] as String? ?? '') ==
          normalizeMusicText(name)) {
        final url = _url(row['strArtistThumb']);
        if (url != null) return url;
      }
    }
    return null;
  }

  Future<String?> _artistDeezer(String name) async {
    final data = await client.get(
      Uri.https('api.deezer.com', '/search/artist', {'q': name, 'limit': '10'}),
    );
    final rows =
        _rows(data, 'data')
            .where(
              (r) =>
                  normalizeMusicText(r['name'] as String? ?? '') ==
                  normalizeMusicText(name),
            )
            .toList()
          ..sort(
            (a, b) => ((b['nb_fan'] as num?) ?? 0).compareTo(
              (a['nb_fan'] as num?) ?? 0,
            ),
          );
    for (final row in rows) {
      final url = _url(row['picture_medium']) ?? _url(row['picture_big']);
      if (url != null) return url;
    }
    return null;
  }

  @override
  Future<String?> album(String artist, String title) => _memo(
    'album:${normalizeMusicText(artist)}:${normalizeMusicText(title)}',
    () async {
      if (artist.trim().isEmpty || title.trim().isEmpty) return null;
      return _first([
        _albumAudioDb(artist, title),
        _albumDeezer(artist, title),
      ]);
    },
  );

  Future<String?> _albumAudioDb(String artist, String title) async {
    final key = normalizeMusicText(artist);
    final rows = await _albums.putIfAbsent(key, () async {
      try {
        final data = await client.get(
          Uri.https('www.theaudiodb.com', '/api/v1/json/123/searchalbum.php', {
            's': artist,
          }),
        );
        return _rows(data, 'album');
      } catch (_) {
        // A temporary network failure must not poison the session cache.
        _albums.remove(key);
        rethrow;
      }
    });
    for (final row in rows) {
      if (normalizeMusicText(row['strAlbum'] as String? ?? '') ==
              normalizeMusicText(title) &&
          normalizeMusicText(row['strArtist'] as String? ?? '') ==
              normalizeMusicText(artist)) {
        final url = _url(row['strAlbumThumb']);
        if (url != null) return url;
      }
    }
    return null;
  }

  Future<String?> _albumDeezer(String artist, String title) async {
    final data = await client.get(
      Uri.https('api.deezer.com', '/search/album', {
        'q': '$artist $title',
        'limit': '15',
      }),
    );
    for (final row in _rows(data, 'data')) {
      final credited = row['artist'] is Map ? row['artist'] as Map : {};
      if (normalizeMusicText(row['title'] as String? ?? '') ==
              normalizeMusicText(title) &&
          normalizeMusicText(credited['name'] as String? ?? '') ==
              normalizeMusicText(artist)) {
        final url = _url(row['cover_medium']) ?? _url(row['cover_big']);
        if (url != null) return url;
      }
    }
    return null;
  }

  @override
  String? cachedAlbum(String artist, String title) =>
      _cache['album:${normalizeMusicText(artist)}:${normalizeMusicText(title)}'];
  @override
  Map<String, String> exportCache() => Map.of(_cache);
  @override
  void restoreCache(Map<String, dynamic> data) {
    for (final entry in data.entries.take(500)) {
      final url = _url(entry.value);
      if (url != null) _cache[entry.key] = url;
    }
  }
}
