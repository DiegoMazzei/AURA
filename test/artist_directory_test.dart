import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:aura/app/aura_app.dart';
import 'package:aura/app/aura_controller.dart';
import 'package:aura/core/catalog/artist_directory.dart';
import 'package:aura/core/catalog/music_json_client.dart';
import 'package:aura/features/catalog/catalog_screen.dart';

import 'fakes.dart';

import 'package:aura/features/youtube/online_track.dart';

const artist = DirectoryArtist(id: 1, name: 'Gemitaiz', genre: 'Hip-Hop/Rap');
const album = DirectoryAlbum(
  id: 2,
  artistId: 1,
  title: 'Disco di prova',
  artist: 'Gemitaiz',
  year: 2026,
  trackCount: 2,
);
const solo = DirectorySong(
  id: 3,
  title: 'Una canzone',
  artist: 'Gemitaiz',
  album: 'Disco di prova',
  artistId: 1,
  albumId: 2,
  number: 1,
  disc: 1,
  seconds: 180,
);
const feat = DirectorySong(
  id: 4,
  title: 'Insieme (feat. Gemitaiz)',
  artist: 'Ospite',
  album: 'Disco di prova',
  artistId: 9,
  albumId: 2,
  number: 2,
  disc: 1,
  seconds: 190,
);

class _Directory implements ArtistDirectory {
  final pending = <String, Completer<DirectoryResults>>{};
  bool delayed = false;
  @override
  Future<DirectoryResults> search(String query) async {
    if (delayed) {
      return (pending[query] ??= Completer<DirectoryResults>()).future;
    }
    return const DirectoryResults(
      artists: [artist],
      albums: [album],
      songs: [solo, feat],
    );
  }

  @override
  Future<List<DirectoryArtist>> searchArtists(String query) async => [artist];
  @override
  Future<List<DirectoryAlbum>> albums(DirectoryArtist a) async => [album];
  @override
  Future<List<DirectorySong>> songs(DirectoryAlbum a) async => [solo, feat];
}

class _LargeDirectory extends _Directory {
  @override
  Future<List<DirectoryAlbum>> albums(DirectoryArtist a) async => List.generate(
    200,
    (i) => DirectoryAlbum(
      id: i,
      artistId: a.id,
      title: 'Album $i',
      artist: a.name,
      year: 2026,
      trackCount: 10,
    ),
  );
}

class _Client implements MusicJsonClient {
  int calls = 0;
  @override
  Future<Object?> get(Uri uri) async {
    calls++;
    if (uri.path == '/search') {
      return {
        'results': [
          {'wrapperType': 'artist', 'artistId': 1, 'artistName': 'Gemitaiz'},
          {
            'wrapperType': 'collection',
            'artistId': 1,
            'artistName': 'Gemitaiz',
            'collectionId': 2,
            'collectionName': 'Disco',
            'releaseDate': '2026-01-01T00:00:00Z',
            'trackCount': 2,
          },
          {
            'wrapperType': 'track',
            'kind': 'song',
            'artistId': 1,
            'artistName': 'Gemitaiz & Ospite',
            'collectionId': 2,
            'collectionName': 'Disco',
            'trackId': 3,
            'trackName': 'Brano',
            'trackTimeMillis': 180000,
          },
          {'wrapperType': 'track', 'kind': 'song'},
        ],
      };
    }
    if (uri.queryParameters['entity'] == 'album') {
      return {
        'results': [
          {
            'wrapperType': 'collection',
            'collectionId': 2,
            'artistId': 1,
            'artistName': 'Gemitaiz',
            'collectionName': 'Disco proprio',
            'releaseDate': '2026-01-01',
          },
          {
            'wrapperType': 'collection',
            'collectionId': 99,
            'artistId': 8,
            'artistName': 'Altro artista',
            'collectionName': 'Solo ospite',
            'releaseDate': '2025-01-01',
          },
        ],
      };
    }
    return {
      'results': [
        {
          'kind': 'song',
          'trackId': 5,
          'collectionId': 2,
          'discNumber': 2,
          'trackNumber': 1,
          'trackName': 'Secondo disco',
        },
        {
          'kind': 'song',
          'trackId': 4,
          'collectionId': 2,
          'discNumber': 1,
          'trackNumber': 2,
          'trackName': 'Seconda',
        },
        {
          'kind': 'song',
          'trackId': 3,
          'collectionId': 2,
          'discNumber': 1,
          'trackNumber': 1,
          'trackName': 'Prima',
        },
        {
          'kind': 'song',
          'trackId': 6,
          'collectionId': 99,
          'trackName': 'Altro album',
        },
      ],
    };
  }
}

void main() {
  testWidgets('large discography only mounts covers near the viewport', (
    tester,
  ) async {
    final c = AuraController(
      audio: FakeAudioEngine(),
      store: MemoryLibraryStore(),
      artistDirectory: _LargeDirectory(),
    );
    await c.initialize();
    await tester.pumpWidget(
      MaterialApp(
        home: ArtistScreen(controller: c, artist: artist),
      ),
    );
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Album'));
    await tester.tap(find.text('Album'));
    await tester.pumpAndSettle();
    expect(find.byType(AlbumRow).evaluate().length, lessThan(20));
    expect(find.text('Album 199'), findsNothing);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
    c.dispose();
  });

  test('mixed catalog works without listening, caches and keeps categories and identities', () async {
    final client = _Client();
    final directory = AppleArtistDirectory(client);
    final r = await directory.search('Gemitaiz');
    expect(r.artists.single.id, 1);
    expect(r.albums.single.title, 'Disco');
    expect(r.songs.single.identity.releaseGroupId, 'apple:2');
    expect(r.songs.single.seconds, 180);
    expect(r.songs.single.identity.artists.first.name, 'Gemitaiz');
    expect(r.songs.single.identity.artists.map((a) => a.id).toSet().length, 2);
    await directory.search('Gemitaiz');
    expect(client.calls, 1);
    final owned = await directory.albums(artist);
    expect(owned.map((a) => a.title), ['Disco proprio']);
    final tracks = await directory.songs(album);
    expect(tracks.map((t) => t.title), ['Prima', 'Seconda', 'Secondo disco']);
  });
  test('collaborations include credited features and exclude unrelated substring names', () {
    const unrelated = DirectorySong(
      id: 8,
      title: 'Altro',
      artist: 'Gemitaizzz',
      album: '',
      artistId: 88,
      albumId: 99,
      number: 1,
      disc: 1,
      seconds: 0,
    );
    expect(artistSongs([solo, feat, unrelated], artist).length, 2);
    expect(
      artistSongs([solo, feat, unrelated], artist, collaborationsOnly: true),
      [feat],
    );
  });
  testWidgets(
    'empty library search opens artist, collaborations, full album and tracklist without playing',
    (tester) async {
      tester.view.physicalSize = const Size(402, 874);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final audio = FakeAudioEngine();
      final c = AuraController(
        audio: audio,
        store: MemoryLibraryStore(),
        artistDirectory: _Directory(),
      );
      await c.initialize();
      await tester.pumpWidget(AuraApp(controller: c));
      await tester.tap(find.text('Cerca').last);
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), 'Gemitaiz');
      await tester.pump(const Duration(milliseconds: 650));
      await tester.pumpAndSettle();
      expect(find.text('Artisti'), findsWidgets);
      await tester.tap(find.byType(ArtistRow).first);
      await tester.pumpAndSettle();
      expect(find.byType(ArtistScreen), findsOneWidget);
      await tester.ensureVisible(find.text('Segui artista'));
      await tester.tap(find.text('Segui artista'));
      await tester.pumpAndSettle();
      expect(c.favoriteArtists.containsKey(artist.id), isTrue);
      expect(find.text('Artista nei preferiti'), findsOneWidget);
      await tester.tap(find.text('Feat.'));
      await tester.pumpAndSettle();
      expect(find.text(feat.title), findsOneWidget);
      expect(find.text(solo.title), findsNothing);
      await tester.tap(find.text('Album'));
      await tester.pumpAndSettle();
      await tester.tap(find.text(album.title));
      await tester.pumpAndSettle();
      expect(find.byType(AlbumScreen), findsOneWidget);
      expect(find.text(solo.title), findsOneWidget);
      expect(audio.loadCount, 0);
      expect(c.libraryTracks, isEmpty);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
      c.dispose();
    },
  );
  testWidgets('catalog search ignores a late response to an older query', (
    tester,
  ) async {
    final d = _Directory()..delayed = true;
    final c = AuraController(
      audio: FakeAudioEngine(),
      store: MemoryLibraryStore(),
      artistDirectory: d,
    );
    await c.initialize();
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: CatalogSearchScreen(controller: c)),
      ),
    );
    await tester.enterText(find.byType(TextField), 'older');
    await tester.pump(const Duration(milliseconds: 650));
    await tester.enterText(find.byType(TextField), 'newer');
    await tester.pump(const Duration(milliseconds: 650));
    d.pending['newer']!.complete(const DirectoryResults(artists: [artist]));
    await tester.pumpAndSettle();
    d.pending['older']!.complete(const DirectoryResults());
    await tester.pumpAndSettle();
    expect(find.text('Gemitaiz'), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
    c.dispose();
  });
  testWidgets(
    'catalog playback resolves one exact version and keeps canonical identity without adding search candidates',
    (tester) async {
      final catalog = FakeMusicCatalog()
        ..results = const [
          OnlineTrack(
            id: 'abcdefghijk',
            title: 'Una canzone',
            artist: 'Gemitaiz',
            durationSeconds: 180,
          ),
          OnlineTrack(
            id: 'lmnopqrstuv',
            title: 'Una canzone Live',
            artist: 'Gemitaiz',
            durationSeconds: 230,
          ),
        ];
      final c = AuraController(
        audio: FakeAudioEngine(),
        store: MemoryLibraryStore(),
        catalog: catalog,
      );
      await c.initialize();
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => TextButton(
                onPressed: () => openCatalogSong(context, c, solo),
                child: const Text('Ascolta fixture'),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('Ascolta fixture'));
      await tester.pumpAndSettle();
      expect(c.current.catalogIdentity?.recordingId, 'apple:3');
      expect(c.current.album, 'Disco di prova');
      expect(c.audio.playing, isTrue);
      expect(c.tracks.length, 1);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
      c.dispose();
    },
  );
}
