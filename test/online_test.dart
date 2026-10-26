import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:aura/app/aura_app.dart';
import 'package:aura/app/aura_controller.dart';
import 'package:aura/features/youtube/online_track.dart';

import 'fakes.dart';

const song = OnlineTrack(
  id: 'M7lc1UVf-VE',
  title: 'Una stella',
  artist: 'AURA',
  durationSeconds: 180,
);
void main() {
  test(
    'YouTube URL parser accepts supported links and rejects spoofed hosts',
    () {
      expect(youtubeVideoId('https://youtu.be/M7lc1UVf-VE?t=2'), song.id);
      expect(
        youtubeVideoId('https://www.youtube.com/watch?v=M7lc1UVf-VE'),
        song.id,
      );
      expect(
        youtubeVideoId('https://m.youtube.com/shorts/M7lc1UVf-VE'),
        song.id,
      );
      expect(
        youtubeVideoId('https://youtube.com.evil.test/watch?v=M7lc1UVf-VE'),
        isNull,
      );
      expect(youtubeVideoId('https://youtu.be/invalid'), isNull);
      expect(parseVideoDuration('1:02:03'), 3723);
      expect(parseVideoDuration('LIVE'), 0);
    },
  );
  test('online favorites playlist and selection persist without becoming local files', () async {
    final store = MemoryLibraryStore();
    final audio = FakeAudioEngine();
    final c = AuraController(
      audio: audio,
      store: store,
      catalog: FakeMusicCatalog(),
    );
    await c.initialize();
    await c.togglePlayback();
    expect(audio.playing, isTrue);
    await c.selectOnline(song);
    expect(audio.playing, isFalse);
    expect(c.onlineCurrent?.id, song.id);
    c.favoriteOnline(song);
    final playlist = c.createOnlinePlaylist('Universo');
    c.addOnlineTrack(playlist, song);
    c.addOnlineTrack(playlist, song);
    await c.save();
    final other = AuraController(
      audio: FakeAudioEngine(),
      store: store,
      catalog: FakeMusicCatalog(),
    );
    await other.initialize();
    expect(other.onlineFavorites, contains(song.id));
    expect(other.playlists.single.trackIds, ['yt:${song.id}']);
    expect(other.tracks.length, 3);
    expect(other.current.id, 'yt:${song.id}');
    expect(other.onlineCurrent, isNull);
    await other.playTrack(other.current);
    expect(other.onlineCurrent, isNull);
    other.dispose();
    c.dispose();
  });
  testWidgets(
    'online search debounces saves favorites and ignores stale responses',
    (tester) async {
      final catalog = FakeMusicCatalog();
      catalog.pending['prima'] = Completer<List<OnlineTrack>>();
      catalog.pending['seconda'] = Completer<List<OnlineTrack>>();
      final c = AuraController(
        audio: FakeAudioEngine(),
        store: MemoryLibraryStore(),
        catalog: catalog,
      );
      await c.initialize();
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(402, 874);
      await tester.pumpWidget(AuraApp(controller: c));
      await tester.tap(find.text('Cerca').last);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 350));
      await tester.enterText(find.byType(TextField), 'prima');
      await tester.pump(const Duration(milliseconds: 460));
      await tester.enterText(find.byType(TextField), 'seconda');
      await tester.pump(const Duration(milliseconds: 460));
      catalog.pending['seconda']!.complete([song]);
      await tester.pump();
      catalog.pending['prima']!.complete([
        const OnlineTrack(
          id: 'dQw4w9WgXcQ',
          title: 'Risposta vecchia',
          artist: 'Fixture',
        ),
      ]);
      await tester.pump();
      expect(find.text('Una stella'), findsOneWidget);
      expect(find.text('Risposta vecchia'), findsNothing);
      await tester.tap(find.byTooltip('Salva video nei preferiti'));
      await tester.pump();
      expect(c.onlineFavorites, contains(song.id));
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
      c.dispose();
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    },
  );
  testWidgets('online failure offers retry without an empty broken screen', (
    tester,
  ) async {
    final catalog = FakeMusicCatalog()..fail = true;
    final c = AuraController(
      audio: FakeAudioEngine(),
      store: MemoryLibraryStore(),
      catalog: catalog,
    );
    await c.initialize();
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(402, 874);
    await tester.pumpWidget(AuraApp(controller: c));
    await tester.tap(find.text('Cerca').last);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 350));
    await tester.enterText(find.byType(TextField), 'musica');
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pump();
    expect(find.text('Un momento di silenzio'), findsOneWidget);
    catalog.fail = false;
    catalog.results = [song];
    await tester.tap(find.text('Riprova'));
    await tester.pump();
    expect(find.text('Una stella'), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
    c.dispose();
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });
}
