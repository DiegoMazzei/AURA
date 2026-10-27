import 'package:flutter/material.dart';
import 'package:aura/app/aura_controller.dart';
import 'package:aura/features/catalog/catalog_screen.dart';

import 'fakes.dart';

import 'package:flutter_test/flutter_test.dart';
import 'package:aura/core/catalog/artist_directory.dart';

DirectoryAlbum album(
  int id, {
  String title = 'Disco',
  int count = 12,
  int year = 2020,
  int artist = 1,
  String explicitness = '',
}) => DirectoryAlbum(
  id: id,
  artistId: artist,
  title: title,
  artist: 'Artista',
  year: year,
  trackCount: count,
  explicitness: explicitness,
);
void main() {
  test('publication years and deluxe editions share one album with every track list retained', () {
    final result = deduplicateAlbums([
      album(1, year: 2020),
      album(2, title: 'Disco (Deluxe)', count: 16, year: 2021),
      album(3, year: 2025),
    ]);
    expect(result.length, 1);
    expect(result.single.editions.map((a) => a.id), containsAll([1, 2, 3]));
  });

  test('Ernia publications with 12, 13 and 14 tracks have one album card', () {
    final result = deduplicateAlbums([
      album(1836402601, title: 'PER SOLDI E PER AMORE', year: 2025, count: 12),
      album(6795194385, title: 'PER SOLDI E PER AMORE', year: 2026, count: 14),
      album(6766251954, title: 'PER SOLDI E PER AMORE', year: 2025, count: 13),
    ]);
    expect(result.length, 1);
    expect(result.single.editions.map((a) => a.trackCount), [12, 13, 14]);
  });

  testWidgets(
    'album editions share one entry and selecting deluxe loads its own tracks',
    (tester) async {
      final family = deduplicateAlbums([
        album(1),
        album(2, title: 'Disco (Deluxe Edition)', count: 16),
      ]).single;
      final directory = _EditionsDirectory();
      final c = AuraController(
        audio: FakeAudioEngine(),
        store: MemoryLibraryStore(),
        artistDirectory: directory,
      );
      await c.initialize();
      await tester.pumpWidget(
        MaterialApp(
          home: AlbumScreen(controller: c, album: family),
        ),
      );
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.byType(DropdownButtonFormField<int>));
      await tester.tap(find.byType(DropdownButtonFormField<int>));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Disco (Deluxe Edition) · 16 brani').last);
      await tester.pumpAndSettle();
      expect(directory.calls, [1, 2]);
      expect(find.text('Traccia edizione 2'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
      c.dispose();
    },
  );

  test('duplicate catalog IDs collapse and prefer explicit recording with alternate IDs retained', () {
    final result = deduplicateAlbums([
      album(1, explicitness: 'cleaned'),
      album(2, explicitness: 'explicit'),
      album(2, explicitness: 'explicit'),
    ]);
    expect(result.length, 1);
    expect(result.single.id, 2);
    expect(result.single.alternateIds, [1]);
  });
  test('deluxe naming variants merge but different music editions do not disappear', () {
    final result = deduplicateAlbums([
      album(1),
      album(2, title: 'Disco (Deluxe Edition)', count: 16),
      album(3, title: 'Disco [Deluxe Version]', count: 16),
      album(4, title: 'Disco (Live)'),
      album(5, title: 'Disco (Remastered)'),
      album(6, year: 2025),
      album(7, artist: 9),
    ]);
    expect(result.length, 4);
    expect(result.first.editions.length, 3);
    expect(result.first.editions.last.alternateIds, [3]);
  });
  test('unknown track counts are kept separate rather than assuming identical content', () {
    expect(
      deduplicateAlbums([album(1, count: 0), album(2, count: 0)]).length,
      2,
    );
  });
}

class _EditionsDirectory implements ArtistDirectory {
  final calls = <int>[];
  @override
  Future<List<DirectoryAlbum>> albums(DirectoryArtist a) async => [];
  @override
  Future<DirectoryResults> search(String q) async => const DirectoryResults();
  @override
  Future<List<DirectoryArtist>> searchArtists(String q) async => [];
  @override
  Future<List<DirectorySong>> songs(DirectoryAlbum a) async {
    calls.add(a.id);
    return [
      DirectorySong(
        id: a.id,
        title: 'Traccia edizione ${a.id}',
        artist: a.artist,
        album: a.title,
        artistId: a.artistId,
        albumId: a.id,
        number: 1,
        disc: 1,
        seconds: 180,
      ),
    ];
  }
}
