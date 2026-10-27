import 'package:aura/app/aura_app.dart';
import 'package:aura/app/aura_controller.dart';
import 'package:aura/core/catalog/artist_directory.dart';
import 'package:aura/core/catalog/home_recommendations.dart';
import 'package:aura/shared/models/music.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'fakes.dart';

class _Directory implements ArtistDirectory {
  final calls = <String>[];
  final failed = <String>{};
  @override
  Future<DirectoryResults> search(String query) async {
    calls.add(query);
    if (failed.contains(query)) throw StateError('offline');
    final id = query == 'Ernia' ? 1 : 2;
    return DirectoryResults(
      albums: [
        DirectoryAlbum(
          id: id,
          artistId: id,
          title: 'Album $query',
          artist: query,
          year: 2025,
          trackCount: 10,
        ),
        const DirectoryAlbum(
          id: 99,
          artistId: 99,
          title: 'Unrelated album',
          artist: 'Other',
          year: 2025,
          trackCount: 10,
        ),
      ],
      songs: [
        for (var i = 1; i <= 4; i++)
          DirectorySong(
            id: id * 10 + i,
            title: 'Brano $query $i',
            artist: query,
            album: 'Album $query',
            artistId: id,
            albumId: id,
            number: i,
            disc: 1,
            seconds: 180,
          ),
      ],
    );
  }

  @override
  Future<List<DirectoryArtist>> searchArtists(String query) async => [];
  @override
  Future<List<DirectoryAlbum>> albums(DirectoryArtist artist) async => [];
  @override
  Future<List<DirectorySong>> songs(DirectoryAlbum album) async => [];
}

void main() {
  testWidgets('first launch stays neutral and performs no artist searches', (
    tester,
  ) async {
    final directory = _Directory();
    final c = AuraController(
      audio: FakeAudioEngine(),
      store: MemoryLibraryStore(),
      artistDirectory: directory,
    );
    await c.initialize();
    await tester.pumpWidget(AuraApp(controller: c));
    await tester.pumpAndSettle();
    expect(find.text('Da dove vuoi iniziare?'), findsOneWidget);
    expect(find.text('Gemitaiz'), findsNothing);
    expect(find.text('The Weeknd'), findsNothing);
    expect(directory.calls, isEmpty);
    expect(c.favoriteArtists, isEmpty);
    await tester.pumpWidget(const SizedBox());
    c.dispose();
  });
  test('taste combines follows, recent plays and favorites without duplicate artist seeds', () {
    final seeds = homeTaste(
      followed: const [DirectoryArtist(id: 1, name: 'Ernia')],
      recent: const [
        Track(id: 'a', source: '', title: 'A', artist: 'ERNIA'),
        Track(id: 'b', source: '', title: 'B', artist: 'Salmo'),
      ],
      favorites: const [Track(id: 'c', source: '', title: 'C', artist: 'Nayt')],
    );
    expect(seeds.first.name.toLowerCase(), 'ernia');
    expect(seeds.first.id, 1);
    expect(seeds.length, 3);
  });
  test('recommendations emit progressively, remove heard songs and unrelated albums', () async {
    final directory = _Directory();
    final pages = await HomeRecommendations(directory)
        .watch(
          const [TasteSeed('Ernia', id: 1), TasteSeed('Salmo', id: 2)],
          heard: {homeSongKey('Brano Ernia 1', 'Ernia')},
        )
        .toList();
    expect(pages.first.albums.map((a) => a.title), ['Album Ernia']);
    expect(pages.last.albums.map((a) => a.title), [
      'Album Ernia',
      'Album Salmo',
    ]);
    expect(pages.last.songs.any((s) => s.title == 'Brano Ernia 1'), isFalse);
    expect(
      pages.last.songs.map((s) => s.id).toSet().length,
      pages.last.songs.length,
    );
  });
  test('a failing artist does not hide results from other seeds', () async {
    final directory = _Directory()..failed.add('Ernia');
    final pages = await HomeRecommendations(directory)
        .watch(const [TasteSeed('Ernia'), TasteSeed('Salmo')])
        .toList();
    expect(pages.last.albums.single.artist, 'Salmo');
  });
  testWidgets(
    'home refreshes when a followed artist changes, not on unrelated notifications',
    (tester) async {
      final directory = _Directory();
      final c = AuraController(
        audio: FakeAudioEngine(),
        store: MemoryLibraryStore(),
        artistDirectory: directory,
      );
      await c.initialize();
      c.toggleArtistFavorite(const DirectoryArtist(id: 1, name: 'Ernia'));
      await tester.pumpWidget(AuraApp(controller: c));
      await tester.pumpAndSettle();
      expect(find.text('Album Ernia'), findsOneWidget);
      expect(directory.calls, ['Ernia']);
      c.setDisplayName('Nome');
      await tester.pumpAndSettle();
      expect(directory.calls, ['Ernia']);
      c.toggleArtistFavorite(const DirectoryArtist(id: 2, name: 'Salmo'));
      await tester.pumpAndSettle();
      expect(find.text('Album Salmo'), findsOneWidget);
      await tester.pumpWidget(const SizedBox());
      c.dispose();
    },
  );
}
