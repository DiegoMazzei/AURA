import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:aura/app/aura_app.dart';
import 'package:aura/app/aura_controller.dart';
import 'package:aura/features/library/library_screen.dart';
import 'package:aura/features/player/player_screen.dart';

import 'fakes.dart';

void main() {
  late AuraController c;
  setUp(() async {
    c = AuraController(
      includeDemoTracks: true,
      audio: FakeAudioEngine(),
      store: MemoryLibraryStore(),
    );
    await c.initialize();
    c.setTheme(ThemeMode.dark);
  });
  tearDown(() => c.dispose());
  Future<void> mount(
    WidgetTester tester, {
    Size size = const Size(402, 874),
  }) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = size;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
    await tester.pumpWidget(AuraApp(controller: c));
    await tester.pump(const Duration(milliseconds: 600));
  }

  testWidgets(
    'library search filters actual collection and handles no result',
    (tester) async {
      await mount(tester);
      await tester.tap(find.text('Libreria').last);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 350));
      await tester.enterText(find.byType(TextField), 'Afterglow');
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.text('Afterglow'), findsWidgets);
      expect(
        find.text('Orbita'),
        findsOneWidget,
      ); // The persistent mini player is retained.
      await tester.enterText(find.byType(TextField), 'nonexistent');
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.text('Nessun risultato'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
    },
  );
  testWidgets('mini player expands controls playback and toggles favorite', (
    tester,
  ) async {
    await mount(tester);
    await tester.tap(
      find
          .descendant(
            of: find.byType(MiniPlayer),
            matching: find.text('Orbita'),
          )
          .first,
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));
    expect(find.byType(PlayerScreen), findsOneWidget);
    await tester.tap(find.byTooltip('Riproduci').last);
    await tester.pump();
    expect(c.audio.playing, isTrue);
    await tester.tap(find.byTooltip('Aggiungi ai preferiti'));
    await tester.pump();
    expect(c.favorites, contains('aura-orbit'));
    await tester.tap(find.byTooltip('Brano successivo').last);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 550));
    expect(c.currentId, 'aura-afterglow');
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
  });
  testWidgets('library creates a real playlist through dialog', (tester) async {
    await mount(tester);
    await tester.tap(find.text('Libreria'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 350));
    expect(find.byType(LibraryScreen), findsOneWidget);
    await tester.tap(find.text('Crea'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 350));
    await tester.enterText(find.byType(TextField).last, 'Le mie stelle');
    await tester.tap(find.text('Salva'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(c.playlists.single.name, 'Le mie stelle');
    expect(find.text('Le mie stelle'), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(seconds: 2));
  });
  testWidgets(
    'metadata import route imports a file and shows searchable songs',
    (tester) async {
      (c.store as MemoryLibraryStore).metadata =
          'title,artist,playlist\nStella,AURA Studio,Notte';
      await mount(tester);
      await tester.tap(find.text('Libreria'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      await tester.ensureVisible(find.text('Playlist'));
      await tester.tap(find.text('Playlist'));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Importa le tue playlist'));
      await tester.pump();
      await tester.tap(find.text('Importa le tue playlist'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      await tester.tap(find.text('Importa JSON o CSV'));
      await tester.runAsync(() async {
        await Future<void>.delayed(const Duration(milliseconds: 250));
      });
      await tester.pump();
      expect(c.importedCollections.single.name, 'Notte');
      expect(find.text('Stella'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
    },
  );
  testWidgets(
    'light theme narrow layout and reduced motion render without overflow',
    (tester) async {
      c.setTheme(ThemeMode.light);
      await mount(tester, size: const Size(320, 740));
      await tester.tap(find.byTooltip('Impostazioni'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      await tester.tap(find.text('Scuro'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      expect(c.themeMode, ThemeMode.dark);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
    },
  );
}
