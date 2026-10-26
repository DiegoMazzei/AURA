import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:aura/features/spotify_import/metadata_import.dart';
import 'package:aura/app/aura_controller.dart';

import 'fakes.dart';

void main() {
  test('Spotify playlist JSON preserves order and deduplicates within each playlist', () {
    final collections = parseMusicExport(
      jsonEncode({
        'playlists': [
          {
            'name': 'Notte',
            'items': [
              {
                'track': {
                  'trackName': 'Uno',
                  'artistName': 'Artista',
                  'albumName': 'Album',
                },
              },
              {
                'track': {'trackName': 'Due', 'artistName': 'Artista'},
              },
              {
                'track': {
                  'trackName': 'Uno',
                  'artistName': 'Artista',
                  'albumName': 'Album',
                },
              },
              {
                'episode': {'name': 'Not music'},
              },
            ],
          },
        ],
      }),
    );
    expect(collections.single.name, 'Notte');
    expect(collections.single.songs.map((s) => s.title), ['Uno', 'Due']);
  });
  test(
    'CSV quotes commas embedded newlines and playlist groups are retained',
    () {
      final result = parseMusicExport(
        'title,artist,album,playlist\n"Hello, night",A,One,Notte\n"A ""star""\nabove",B,Two,Alba',
      );
      expect(result.length, 2);
      expect(result.first.songs.single.title, 'Hello, night');
      expect(result.last.songs.single.title, 'A "star"\nabove');
      expect(
        () => parseMusicExport('title,artist\n"oops,A'),
        throwsFormatException,
      );
    },
  );
  test(
    'unknown formats report failure rather than creating empty playlists',
    () {
      expect(
        () => parseMusicExport('{"profile":{"name":"Private"}}'),
        throwsFormatException,
      );
      expect(
        () => parseMusicExport('email,password\na,b'),
        throwsFormatException,
      );
    },
  );
  test(
    'metadata import is persistent idempotent and separate from playable audio',
    () async {
      final store = MemoryLibraryStore()
        ..metadata = 'title,artist,playlist\nOrbit,Studio,Demo';
      final c = AuraController(audio: FakeAudioEngine(), store: store);
      await c.initialize();
      expect(await c.importMusicMetadata(), 1);
      expect(await c.importMusicMetadata(), 0);
      expect(c.tracks.length, 2);
      expect(c.importedCollections.single.songs.single.artist, 'Studio');
      await c.save();
      final restored = AuraController(audio: FakeAudioEngine(), store: store);
      await restored.initialize();
      expect(restored.importedCollections.single.name, 'Demo');
      final uri =
          restored.importedCollections.single.songs.single.youtubeSearch;
      expect(uri.host, 'www.youtube.com');
      expect(uri.queryParameters['search_query'], 'Orbit Studio');
      restored.dispose();
      c.dispose();
    },
  );
}
