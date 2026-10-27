import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:aura/app/aura_app.dart';
import 'package:aura/app/aura_controller.dart';
import 'package:aura/core/lyrics/lyrics_provider.dart';
import 'package:aura/features/karaoke/lyrics_search_sheet.dart';
import 'package:aura/shared/models/music.dart';

import 'fakes.dart';

class _Lyrics implements LyricsProvider {
  @override
  Future<List<LyricsCandidate>> search(Track track) async => const [
    LyricsCandidate(
      id: 1,
      title: 'Versione sincronizzata',
      artist: 'Fixture',
      synced: '[00:02.00]Una riga inventata\n[00:05.00]Un’altra riga inventata',
      plain: 'Una riga inventata\nUn’altra riga inventata',
    ),
    LyricsCandidate(
      id: 2,
      title: 'Versione semplice',
      artist: 'Fixture',
      plain: 'Solo una frase inventata',
    ),
  ];
}

void main() {
  for (final synchronized in [true, false]) {
    testWidgets('lyrics selection persists source and timing: $synchronized', (
      tester,
    ) async {
      final store = MemoryLibraryStore();
      final audio = FakeAudioEngine();
      final c = AuraController(
        includeDemoTracks: true,
        audio: audio,
        store: store,
        lyricsProvider: _Lyrics(),
      );
      await c.initialize();
      await c.playTrack(c.current);
      await tester.pumpWidget(AuraApp(controller: c));
      final context = tester.element(find.byType(AuraShell));
      findLyrics(context, c, c.current);
      await tester.pumpAndSettle();
      expect(find.text('Consulta Genius'), findsOneWidget);
      await tester.tap(
        find.text(
          synchronized ? 'Versione sincronizzata' : 'Versione semplice',
        ),
      );
      await tester.pumpAndSettle();
      expect(audio.playing, isTrue);
      expect(c.current.lyricsSource, 'LRCLIB');
      expect(c.current.lyrics.length, synchronized ? 2 : 0);
      if (synchronized) {
        expect(c.current.lyrics.first.at, const Duration(seconds: 2));
      }
      await c.save();
      await tester.pumpWidget(const SizedBox());
      c.dispose();
      final restored = AuraController(
        includeDemoTracks: true,
        audio: FakeAudioEngine(),
        store: store,
      );
      await restored.initialize();
      expect(restored.current.lyricsSource, 'LRCLIB');
      expect(restored.current.plainLyrics, isNotEmpty);
      expect(restored.current.lyrics.length, synchronized ? 2 : 0);
      restored.dispose();
    });
  }
}
