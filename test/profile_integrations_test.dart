import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:aura/app/aura_controller.dart';
import 'package:aura/core/catalog/artist_directory.dart';
import 'package:aura/core/catalog/catalog_identity.dart';
import 'package:aura/core/catalog/music_json_client.dart';
import 'package:aura/core/lyrics/lyrics_provider.dart';
import 'package:aura/features/catalog/catalog_screen.dart';
import 'package:aura/features/spotify_import/metadata_import.dart';
import 'package:aura/features/spotify_import/spotify_connection.dart';
import 'package:aura/shared/models/music.dart';

import 'fakes.dart';

class _LyricsClient implements MusicJsonClient {
  final calls = <Uri>[];
  @override
  Future<Object?> get(Uri uri) async {
    calls.add(uri);
    if (uri.queryParameters.containsKey('q')) {
      return [
        {
          'id': 1,
          'trackName': 'Canzone',
          'artistName': 'Artista',
          'duration': 180,
          'syncedLyrics': '[00:01.00]Testo di prova',
          'plainLyrics': 'Testo di prova',
        },
      ];
    }
    return null;
  }
}

void main() {
  test(
    'correct lyric text remains available when synchronized timing differs',
    () async {
      final c = AuraController(
        audio: FakeAudioEngine(),
        store: MemoryLibraryStore(),
        lyricsProvider: LrclibLyricsProvider(_LyricsClient()),
      );
      await c.initialize();
      const seed = Track(
        id: 'song',
        source: 'file',
        title: 'Canzone',
        artist: 'Artista',
        durationSeconds: 210,
      );
      c.tracks.add(seed);
      await c.fetchLyrics(seed);
      expect(c.tracks.single.plainLyrics, 'Testo di prova');
      expect(c.tracks.single.lyrics, isEmpty);
      c.dispose();
    },
  );

  test('personal name and equalizer settings persist without a fixed user identity', () async {
    final store = MemoryLibraryStore();
    final c = AuraController(audio: FakeAudioEngine(), store: store);
    await c.initialize();
    expect(c.displayName, isEmpty);
    c.setDisplayName('  Giulia  Rossi ');
    await c.setEqualizer(enabled: true, preset: [4, 2, 0, -1, 1]);
    await c.save();
    c.dispose();
    final r = AuraController(audio: FakeAudioEngine(), store: store);
    await r.initialize();
    expect(r.displayName, 'Giulia Rossi');
    expect(r.equalizerEnabled, isTrue);
    expect(r.equalizerGains, [4, 2, 0, -1, 1]);
    r.dispose();
  });
  test(
    'lyrics use normalized title and alternate query, then cache results',
    () async {
      final client = _LyricsClient();
      final p = LrclibLyricsProvider(client);
      const track = Track(
        id: 'x',
        source: 'x',
        title: 'Canzone (feat. Ospite)',
        artist: 'Artista, Ospite',
        durationSeconds: 180,
        catalogIdentity: CatalogIdentity(
          recordingId: 'x',
          artists: [CatalogArtist(id: 'a', name: 'Artista')],
        ),
      );
      final found = await p.search(track);
      expect(found.single.synchronized, isTrue);
      expect(lyricsMatch(track, found.single), isTrue);
      expect(client.calls.length, 3);
      expect(client.calls.first.queryParameters['track_name'], 'Canzone');
      await p.search(track);
      expect(client.calls.length, 3);
    },
  );
  test(
    'Spotify PKCE verifies callback state and never includes a client secret',
    () {
      final login = SpotifyLogin('a' * 32);
      expect(login.url.queryParameters['code_challenge_method'], 'S256');
      expect(login.url.queryParameters.containsKey('client_secret'), isFalse);
      expect(
        login.callbackCode('$spotifyRedirect?code=ok&state=${login.state}'),
        'ok',
      );
      expect(
        () => login.callbackCode('$spotifyRedirect?code=bad&state=wrong'),
        throwsFormatException,
      );
      expect(
        () =>
            login.callbackCode('other://callback?code=ok&state=${login.state}'),
        throwsFormatException,
      );
    },
  );
  test(
    'Spotify imports real favorite and playlist entries idempotently',
    () async {
      final row = {
        'item': {
          'type': 'track',
          'name': 'Canzone',
          'artists': [
            {'name': 'Artista'},
          ],
          'album': {'name': 'Disco'},
          'uri': 'spotify:track:abc123',
          'duration_ms': 180000,
        },
      };
      final song = spotifyImportedSong(row)!;
      expect(song.durationSeconds, 180);
      expect(
        spotifyImportedSong({
          'item': {'type': 'episode'},
        }),
        isNull,
      );
      final c = AuraController(
        audio: FakeAudioEngine(),
        store: MemoryLibraryStore(),
      );
      await c.initialize();
      final collections = [
        ImportedCollection(name: 'Preferiti', sourceId: 'saved', songs: [song]),
        ImportedCollection(
          name: 'La mia playlist',
          sourceId: 'playlist123',
          songs: [song],
        ),
      ];
      await c.importSpotifyCollections(collections);
      await c.importSpotifyCollections(collections);
      expect(c.tracks.length, 1);
      expect(c.favorites.single, 'catalog:spotify:abc123');
      expect(c.playlists.length, 1);
      expect(c.playlists.single.trackIds.length, 1);
      c.dispose();
    },
  );
  testWidgets('tapping a known artist opens its page directly', (tester) async {
    final c = AuraController(
      audio: FakeAudioEngine(),
      store: MemoryLibraryStore(),
      artistDirectory: _Directory(),
    );
    await c.initialize();
    const track = Track(
      id: 'x',
      source: '',
      title: 'Brano',
      artist: 'Artista',
      catalogIdentity: CatalogIdentity(
        recordingId: 'x',
        artists: [CatalogArtist(id: 'apple:42', name: 'Artista')],
      ),
    );
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => TextButton(
            onPressed: () => openTrackArtist(context, c, track),
            child: const Text('Artista'),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Artista'));
    await tester.pumpAndSettle();
    expect(find.byType(ArtistScreen), findsOneWidget);
    expect(find.text('Segui artista'), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
    c.dispose();
  });
}

class _Directory implements ArtistDirectory {
  @override
  Future<List<DirectoryAlbum>> albums(DirectoryArtist artist) async => [];
  @override
  Future<DirectoryResults> search(String query) async =>
      const DirectoryResults();
  @override
  Future<List<DirectoryArtist>> searchArtists(String query) async => [];
  @override
  Future<List<DirectorySong>> songs(DirectoryAlbum album) async => [];
}
