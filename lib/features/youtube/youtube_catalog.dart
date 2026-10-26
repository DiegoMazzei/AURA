import 'package:youtube_explode_dart/youtube_explode_dart.dart';

import 'online_track.dart';

abstract class MusicCatalog {
  Future<List<OnlineTrack>> search(String query);
  void dispose();
}

/// Keyless metadata discovery using public YouTube search pages.
/// This is an unofficial adapter, not the YouTube Data API. It never requests
/// stream manifests, media URLs, deciphering, cookies, credentials or downloads.
class YoutubeCatalog implements MusicCatalog {
  final _active = <YoutubeExplode>{};
  final _cache = <String, ({DateTime at, List<OnlineTrack> tracks})>{};
  @override
  Future<List<OnlineTrack>> search(String query) async {
    final key = query.trim().toLowerCase();
    if (key.isEmpty) return [];
    final cached = _cache[key];
    if (cached != null && DateTime.now().difference(cached.at).inMinutes < 10) {
      return cached.tracks;
    }
    final client = YoutubeExplode();
    _active.add(client);
    try {
      final results = await client.search
          .searchContent(query.trim(), filter: TypeFilters.video)
          .timeout(const Duration(seconds: 18));
      final tracks = results
          .whereType<SearchVideo>()
          .take(20)
          .map(
            (v) => OnlineTrack(
              id: v.id.value,
              title: v.title,
              artist: v.author,
              durationSeconds: parseVideoDuration(v.duration),
            ),
          )
          .toList();
      if (_cache.length >= 40) _cache.remove(_cache.keys.first);
      _cache[key] = (at: DateTime.now(), tracks: tracks);
      return tracks;
    } finally {
      _active.remove(client);
      client.close();
    }
  }

  @override
  void dispose() {
    for (final client in _active) {
      client.close();
    }
    _active.clear();
  }
}
