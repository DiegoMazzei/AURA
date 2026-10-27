import 'package:flutter_test/flutter_test.dart';
import 'package:aura/core/catalog/music_json_client.dart';
import 'package:aura/core/catalog/musicbrainz_catalog.dart';
import 'package:aura/shared/models/music.dart';

class _UnavailablePrimary implements MusicJsonClient {
  final calls = <Uri>[];
  @override
  Future<Object?> get(Uri uri) async {
    calls.add(uri);
    if (uri.host == 'musicbrainz.org') throw StateError('busy');
    return {
      'results': [
        {
          'kind': 'song',
          'trackId': 1,
          'artistId': 2,
          'collectionId': 3,
          'trackName': 'Orizzonte',
          'artistName': 'Artista',
          'collectionName': 'Disco',
          'trackTimeMillis': 180000,
          'trackViewUrl': 'https://music.apple.com/test',
        },
        {
          'kind': 'song',
          'trackId': 4,
          'artistId': 5,
          'collectionId': 6,
          'trackName': 'Altro',
          'artistName': 'Omonimo',
          'trackTimeMillis': 180000,
        },
      ],
    };
  }
}

void main() {
  test('unavailable primary catalog uses factual fallback and caches without media', () async {
    final client = _UnavailablePrimary();
    final catalog = ResilientMetadataCatalog(client);
    const track = Track(
      id: 'yt:fixture',
      title: 'Orizzonte',
      artist: 'Artista',
      source: 'fixture',
      isYoutube: true,
      durationSeconds: 180,
    );
    final matches = await catalog.search(track);
    expect(matches.first.identity.provider, 'Apple');
    expect(matches.first.identity.artists.single.id, 'apple:2');
    expect(matches.first.identity.releaseGroupId, 'apple:3');
    expect(matches.first.identity.artworkUrl, isNull);
    expect(isConfidentCatalogMatch(track, matches.first), isTrue);
    expect(isConfidentCatalogMatch(track, matches.last), isFalse);
    expect(
      track.copyWith(catalogIdentity: matches.first.identity).artworkUrl,
      'https://i.ytimg.com/vi/fixture/hqdefault.jpg',
    );
    await catalog.search(track);
    expect(client.calls.length, 2);
  });
}
