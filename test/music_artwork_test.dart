import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:aura/core/artwork/music_artwork.dart';
import 'package:aura/core/catalog/music_json_client.dart';

class _Client implements MusicJsonClient {
  final calls = <Uri>[];
  bool offline = false;
  @override
  Future<Object?> get(Uri uri) async {
    calls.add(uri);
    if (offline) throw StateError('offline');
    if (uri.path.endsWith('search.php')) {
      return {
        'artists': [
          {
            'strArtist': 'Un omonimo diverso',
            'strArtistThumb': 'https://images.test/wrong.jpg',
          },
          {
            'strArtist': 'Gemitaiz',
            'strArtistThumb': 'https://images.test/artist.jpg',
          },
        ],
      };
    }
    if (uri.path.endsWith('searchalbum.php')) {
      return {
        'album': [
          {
            'strArtist': 'Gemitaiz',
            'strAlbum': 'Disco',
            'strAlbumThumb': 'https://images.test/album.jpg',
          },
        ],
      };
    }
    return {
      'data': [
        {
          'title': 'Altro disco',
          'artist': {'name': 'Gemitaiz'},
          'cover_big': 'https://images.test/wrong.jpg',
        },
        {
          'title': 'Disco nuovo',
          'artist': {'name': 'Gemitaiz'},
          'cover_big': 'https://images.test/new.jpg',
        },
      ],
    };
  }
}

class _SlowClient implements MusicJsonClient {
  final slow = Completer<Object?>();
  @override
  Future<Object?> get(Uri uri) {
    if (uri.host == 'www.theaudiodb.com') return slow.future;
    return Future.value({
      'data': [
        {'name': 'Gemitaiz', 'picture_medium': 'https://images.test/fast.jpg'},
      ],
    });
  }
}

void main() {
  test(
    'a slow provider does not delay a matching photo from another source',
    () async {
      final client = _SlowClient();
      final images = MusicArtwork(client);
      expect(
        await images.artist('Gemitaiz').timeout(const Duration(seconds: 1)),
        'https://images.test/fast.jpg',
      );
      client.slow.complete(null);
      expect(await images.artist('Gemitaiz'), 'https://images.test/fast.jpg');
    },
  );
  test('artist photos and album covers require matching names, deduplicate and persist URLs', () async {
    final client = _Client();
    final images = MusicArtwork(client);
    final same = await Future.wait([
      images.artist('Gemitaiz'),
      images.artist('Gemitaiz'),
    ]);
    expect(same, [
      'https://images.test/artist.jpg',
      'https://images.test/artist.jpg',
    ]);
    expect(client.calls.length, 2);
    expect(
      await images.album('Gemitaiz', 'Disco'),
      'https://images.test/album.jpg',
    );
    expect(
      await images.album('Gemitaiz', 'Disco nuovo'),
      'https://images.test/new.jpg',
    );
    final offline = _Client()..offline = true;
    final restored = MusicArtwork(offline)..restoreCache(images.exportCache());
    expect(await restored.artist('Gemitaiz'), 'https://images.test/artist.jpg');
    expect(
      await restored.album('Gemitaiz', 'Disco nuovo'),
      'https://images.test/new.jpg',
    );
    expect(offline.calls, isEmpty);
  });
  test('temporary missing images have bounded retries and insecure cache URLs are ignored', () async {
    final client = _Client()..offline = true;
    final images = MusicArtwork(client)
      ..restoreCache({'artist:gemitaiz': 'http://bad.test/image.jpg'});
    expect(await images.artist('Gemitaiz'), isNull);
    expect(await images.artist('Gemitaiz'), isNull);
    expect(client.calls.length, 2);
  });
}
