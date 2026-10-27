import 'music_json_client.dart';
import 'musicbrainz_catalog.dart' show normalizeMusicText;

class SuggestedArtist {
  const SuggestedArtist({required this.name, this.id, this.imageUrl});
  final String name;
  final int? id;
  final String? imageUrl;
  String get key =>
      id == null ? 'name:${normalizeMusicText(name)}' : 'deezer:$id';
}

abstract class ArtistRecommendations {
  Future<List<SuggestedArtist>> related(SuggestedArtist artist);
}

/// Related artists are catalog recommendations, not inferred listening history.
class DeezerArtistRecommendations implements ArtistRecommendations {
  DeezerArtistRecommendations(this.client);
  final MusicJsonClient client;
  final _cache = <String, List<SuggestedArtist>>{};
  final _pending = <String, Future<List<SuggestedArtist>>>{};
  @override
  Future<List<SuggestedArtist>> related(SuggestedArtist artist) {
    final cached = _cache[artist.key];
    if (cached != null) return Future.value(cached);
    return _pending.putIfAbsent(artist.key, () async {
      try {
        final result = await _load(artist);
        if (_cache.length >= 60) _cache.remove(_cache.keys.first);
        _cache[artist.key] = result;
        return result;
      } finally {
        _pending.remove(artist.key);
      }
    });
  }

  List<Map> _rows(Object? response) {
    if (response is Map && response['error'] != null) {
      throw const MusicServiceException(
        'Suggerimenti non disponibili. Riprova.',
      );
    }
    if (response is! Map || response['data'] is! List) {
      throw const MusicServiceException(
        'Suggerimenti non disponibili. Riprova.',
      );
    }
    return (response['data'] as List).whereType<Map>().toList();
  }

  Future<List<SuggestedArtist>> _load(SuggestedArtist artist) async {
    int? id = artist.id;
    if (id == null) {
      final matches =
          _rows(
                await client.get(
                  Uri.https('api.deezer.com', '/search/artist', {
                    'q': artist.name,
                    'limit': '15',
                  }),
                ),
              )
              .where(
                (r) =>
                    r['id'] is num &&
                    normalizeMusicText(r['name'] as String? ?? '') ==
                        normalizeMusicText(artist.name),
              )
              .toList()
            ..sort(
              (a, b) => ((b['nb_fan'] as num?) ?? 0).compareTo(
                (a['nb_fan'] as num?) ?? 0,
              ),
            );
      if (matches.isEmpty) return [];
      id = (matches.first['id'] as num).toInt();
    }
    final rows = _rows(
      await client.get(
        Uri.https('api.deezer.com', '/artist/$id/related', {'limit': '18'}),
      ),
    );
    final result = <SuggestedArtist>[];
    final ids = <int>{id}, names = <String>{normalizeMusicText(artist.name)};
    for (final row in rows) {
      if (row['id'] is! num || row['name'] is! String) continue;
      final aid = (row['id'] as num).toInt();
      final name = (row['name'] as String).trim();
      final normalized = normalizeMusicText(name);
      if (normalized.isEmpty || ids.contains(aid) || names.contains(normalized)) {
        continue;
      }
      ids.add(aid);
      names.add(normalized);
      final image = Uri.tryParse(row['picture_medium'] as String? ?? '');
      result.add(
        SuggestedArtist(
          id: aid,
          name: name,
          imageUrl: image?.scheme == 'https' && image!.host.isNotEmpty
              ? image.toString()
              : null,
        ),
      );
      if (result.length == 12) break;
    }
    return result;
  }
}
