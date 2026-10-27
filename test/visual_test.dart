import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:aura/app/aura_app.dart';
import 'package:aura/app/aura_controller.dart';
import 'package:aura/features/player/player_screen.dart';
import 'package:aura/features/karaoke/karaoke_screen.dart';

import 'fakes.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() async {
    final loader = FontLoader('Roboto');
    loader.addFont(rootBundle.load('assets/fonts/Roboto-Regular.ttf'));
    await loader.load();
    final icons = FontLoader('MaterialIcons')
      ..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'));
    await icons.load();
  });
  for (final theme in [ThemeMode.dark, ThemeMode.light]) {
    testWidgets('visual Home ${theme.name}', (tester) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(402, 874);
      tester.platformDispatcher.accessibilityFeaturesTestValue =
          const FakeAccessibilityFeatures(disableAnimations: true);
      final c = AuraController(
        includeDemoTracks: true,
        audio: FakeAudioEngine(),
        store: MemoryLibraryStore(),
        now: () => DateTime(2026, 10, 27, 21),
      );
      await c.initialize();
      c.setTheme(theme);
      await tester.pumpWidget(AuraApp(controller: c));
      await tester.runAsync(
        () => precacheImage(
          const AssetImage('assets/images/cosmic-ribbon.png'),
          tester.element(find.byType(AuraApp)),
        ),
      );
      await tester.pump(const Duration(seconds: 1));
      await expectLater(
        find.byType(AuraApp),
        matchesGoldenFile('../docs/previews/home-${theme.name}.png'),
      );
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
      c.dispose();
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
      tester.platformDispatcher.clearAccessibilityFeaturesTestValue();
    });
  }
  testWidgets('visual player and synchronized lyrics', (tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(402, 874);
    tester.platformDispatcher.accessibilityFeaturesTestValue =
        const FakeAccessibilityFeatures(disableAnimations: true);
    final audio = FakeAudioEngine();
    final c = AuraController(
      includeDemoTracks: true,
      audio: audio,
      store: MemoryLibraryStore(),
    );
    await c.initialize();
    c.setTheme(ThemeMode.dark);
    await tester.pumpWidget(AuraApp(controller: c));
    await tester.runAsync(
      () => precacheImage(
        const AssetImage('assets/images/cosmic-ribbon.png'),
        tester.element(find.byType(AuraApp)),
      ),
    );
    await tester.pump();
    openPlayer(tester.element(find.byType(MiniPlayer)), c);
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    await expectLater(
      find.byType(AuraApp),
      matchesGoldenFile('../docs/previews/player-dark.png'),
    );
    final context = tester.element(find.byType(PlayerScreen));
    Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => KaraokeScreen(controller: c)),
    );
    await c.togglePlayback();
    audio.advance(const Duration(seconds: 17));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    await expectLater(
      find.byType(AuraApp),
      matchesGoldenFile('../docs/previews/karaoke-dark.png'),
    );
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
    c.dispose();
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
    tester.platformDispatcher.clearAccessibilityFeaturesTestValue();
  });
}
