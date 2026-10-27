import 'dart:async';

import 'package:aura/app/aura_controller.dart';
import 'package:aura/core/catalog/artist_directory.dart';
import 'package:aura/core/catalog/artist_recommendations.dart';
import 'package:aura/core/catalog/music_json_client.dart';
import 'package:aura/features/discovery/artist_discovery_screen.dart';
import 'package:aura/features/catalog/catalog_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:aura/core/design/aura_design.dart';
import 'package:flutter_test/flutter_test.dart';

import 'fakes.dart';

class _Client implements MusicJsonClient {
  final calls = <Uri>[];
  bool fail = false;
  @override
  Future<Object?> get(Uri uri) async {
    calls.add(uri);
    if (fail) throw const MusicServiceException('offline');
    if (uri.path == '/search/artist') {
      return {
        'data': [
          {'id': 1, 'name': 'Gemitaiz Tribute', 'nb_fan': 999999},
          {'id': 2, 'name': 'Gemitaiz', 'nb_fan': 9},
          {'id': 3, 'name': 'Gemitaiz', 'nb_fan': 146035},
        ],
      };
    }
    return {
      'data': [
        {'id': 3, 'name': 'Gemitaiz'},
        {
          'id': 4,
          'name': 'MadMan',
          'picture_medium': 'https://cdn.example/madman.jpg',
        },
        {'id': 5, 'name': 'MADMAN'},
        {'id': 6, 'name': 'Salmo', 'picture_medium': 'file:///bad'},
        {'id': 7, 'name': ''},
      ],
    };
  }
}

class _Recommendations implements ArtistRecommendations {
  final ernia = Completer<List<SuggestedArtist>>();
  @override
  Future<List<SuggestedArtist>> related(SuggestedArtist artist) =>
      artist.name == 'Ernia'
      ? ernia.future
      : Future.value(const [
          SuggestedArtist(name: 'Ernia', id: 4),
          SuggestedArtist(name: 'Salmo', id: 5),
          SuggestedArtist(name: 'Nayt', id: 6),
          SuggestedArtist(name: 'Marracash', id: 7),
          SuggestedArtist(name: 'MadMan', id: 8),
          SuggestedArtist(name: 'Nitro', id: 9),
        ]);
}

class _Directory implements ArtistDirectory {
  @override
  Future<DirectoryResults> search(String q) async => const DirectoryResults();
  @override
  Future<List<DirectoryArtist>> searchArtists(String q) async => [
    DirectoryArtist(id: 1, name: q),
  ];
  @override
  Future<List<DirectoryAlbum>> albums(DirectoryArtist a) async => [];
  @override
  Future<List<DirectorySong>> songs(DirectoryAlbum a) async => [];
}

void main() {
  test('exact artist identity beats tribute, popular homonym wins, results deduplicate and cache', () async {
    final client = _Client();
    final provider = DeezerArtistRecommendations(client);
    const seed = SuggestedArtist(name: 'Gemitaiz');
    final results = await Future.wait([
      provider.related(seed),
      provider.related(seed),
    ]);
    expect(client.calls.length, 2);
    expect(client.calls.last.path, '/artist/3/related');
    expect(results.first.map((a) => a.name), ['MadMan', 'Salmo']);
    expect(results.first.last.imageUrl, isNull);
    await provider.related(seed);
    expect(client.calls.length, 2);
  });
  test(
    'failed requests can be retried rather than cached as empty suggestions',
    () async {
      final client = _Client()..fail = true;
      final provider = DeezerArtistRecommendations(client);
      const seed = SuggestedArtist(name: 'Gemitaiz');
      await expectLater(
        provider.related(seed),
        throwsA(isA<MusicServiceException>()),
      );
      client.fail = false;
      expect(await provider.related(seed), hasLength(2));
    },
  );
  testWidgets(
    'selection explores similar artists, ignores stale results, and opens discography without following',
    (tester) async {
      final recommendations = _Recommendations();
      final c = AuraController(
        audio: FakeAudioEngine(),
        store: MemoryLibraryStore(),
        artistRecommendations: recommendations,
        artistDirectory: _Directory(),
      );
      await c.initialize();
      await tester.pumpWidget(
        MaterialApp(
          home: ArtistDiscoveryScreen(
            controller: c,
            starters: const [SuggestedArtist(name: 'Gemitaiz')],
          ),
        ),
      );
      await tester.tap(find.text('Gemitaiz'));
      await tester.pumpAndSettle();
      expect(find.text('Se ti piace Gemitaiz'), findsOneWidget);
      await tester.tap(find.text('Ernia'));
      await tester.pump();
      expect(find.text('Se ti piace Ernia'), findsOneWidget);
      await tester.tap(find.widgetWithText(ActionChip, 'Gemitaiz'));
      await tester.pumpAndSettle();
      recommendations.ernia.complete(const [
        SuggestedArtist(name: 'Stale artist'),
      ]);
      await tester.pumpAndSettle();
      expect(find.text('Stale artist'), findsNothing);
      expect(find.text('Se ti piace Gemitaiz'), findsOneWidget);
      expect(c.favoriteArtists, isEmpty);
      await tester.tap(find.text('Apri artista'));
      await tester.pumpAndSettle();
      expect(find.byType(ArtistScreen), findsOneWidget);
      expect(c.favoriteArtists, isEmpty);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
      c.dispose();
    },
  );
  testWidgets('discovery mobile layout', (tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(402, 874);
    final font = FontLoader('Roboto')
      ..addFont(rootBundle.load('assets/fonts/Roboto-Regular.ttf'));
    final icons = FontLoader('MaterialIcons')
      ..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'));
    await font.load();
    await icons.load();
    final c = AuraController(
      audio: FakeAudioEngine(),
      store: MemoryLibraryStore(),
      artistRecommendations: _Recommendations(),
      artistDirectory: _Directory(),
    );
    await c.initialize();
    await tester.pumpWidget(
      MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: auraTheme(Brightness.dark),
        home: ArtistDiscoveryScreen(
          controller: c,
          seed: const SuggestedArtist(name: 'Gemitaiz'),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('../docs/previews/discovery-dark.png'),
    );
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
    c.dispose();
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });
}
