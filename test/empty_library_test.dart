import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:aura/app/aura_controller.dart';
import 'package:aura/app/aura_app.dart';
import 'package:aura/shared/models/music.dart';

import 'fakes.dart';

void main() {
  testWidgets(
    'production starts empty without demo music or an active player',
    (tester) async {
      final audio = FakeAudioEngine();
      final c = AuraController(audio: audio, store: MemoryLibraryStore());
      await c.initialize();
      expect(c.tracks, isEmpty);
      expect(c.hasCurrent, isFalse);
      await c.playTrack(c.current);
      expect(c.busy, isFalse);
      expect(audio.loadCount, 0);
      await tester.pumpWidget(AuraApp(controller: c));
      await tester.pumpAndSettle();
      expect(find.text('Orbita'), findsNothing);
      expect(find.text('Afterglow'), findsNothing);
      expect(find.text('Cerca la tua musica'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
      c.dispose();
    },
  );
  test(
    'upgrade removes stock assets and retains personal songs and favorites',
    () async {
      final store = MemoryLibraryStore()
        ..data = {
          'tracks': [
            ...demoTracks.map((t) => t.toJson()),
            const Track(
              id: 'mine',
              title: 'Personale',
              artist: 'Artista',
              source: '/audio.m4a',
            ).toJson(),
          ],
          'current': demoTracks.first.id,
          'favorites': [demoTracks.first.id, 'mine'],
          'recent': [demoTracks.first.id, 'mine'],
          'queue': [demoTracks.first.id, 'mine'],
        };
      final c = AuraController(audio: FakeAudioEngine(), store: store);
      await c.initialize();
      expect(c.tracks.map((t) => t.id), ['mine']);
      expect(c.favorites, {'mine'});
      expect(c.recent, ['mine']);
      expect(c.queue, ['mine']);
      expect(c.currentId, 'mine');
      c.dispose();
    },
  );
}
