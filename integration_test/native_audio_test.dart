import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:aura/core/audio/audio_engine.dart';
import 'package:aura/core/storage/library_store.dart';
import 'package:aura/shared/models/music.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  testWidgets(
    'real native audio asset playback pause seek and file persistence',
    (tester) async {
      final audio = LocalAudioEngine();
      Directory? temp;
      try {
        await tester.runAsync(() async {
          await audio.load(demoTracks.first);
          expect(audio.duration.inSeconds, greaterThanOrEqualTo(39));
          audio.play();
          await Future<void>.delayed(const Duration(milliseconds: 900));
          expect(audio.playing, isTrue);
          expect(audio.position.inMilliseconds, greaterThan(100));
          await audio.pause();
          expect(audio.playing, isFalse);
          await audio.seek(const Duration(seconds: 8));
          expect(audio.position.inMilliseconds, inInclusiveRange(7900, 8200));
          await audio.load(demoTracks.last);
          expect(audio.duration.inSeconds, greaterThanOrEqualTo(39));
          temp = await Directory.systemTemp.createTemp('aura-native-test-');
          final store = DeviceLibraryStore(directory: () async => temp!);
          await store.write({
            'version': 1,
            'favorites': ['native-test'],
          });
          expect((await store.read())?['favorites'], ['native-test']);
          debugPrint(
            'AURA_NATIVE_AUDIO_SMOKE_PASSED: decode/play/position/pause/seek/second-asset/persistence',
          );
        });
      } finally {
        audio.dispose();
        if (temp != null) await temp!.delete(recursive: true);
      }
    },
  );
  testWidgets(
    'real native YouTube source plays independently of a video view',
    (tester) async {
      final audio = LocalAudioEngine();
      try {
        await tester.runAsync(() async {
          await audio.load(
            const Track(
              id: 'yt:M7lc1UVf-VE',
              title: 'YouTube API Demo',
              artist: 'YouTube Developers',
              source: 'M7lc1UVf-VE',
              isYoutube: true,
            ),
          );
          expect(audio.duration.inSeconds, greaterThan(5));
          audio.play();
          await Future<void>.delayed(const Duration(seconds: 2));
          expect(audio.playing, isTrue);
          expect(audio.position.inMilliseconds, greaterThan(200));
          await audio.seek(const Duration(seconds: 4));
          await audio.pause();
          expect(audio.position.inMilliseconds, inInclusiveRange(3900, 4400));
          expect(audio.playing, isFalse);
          debugPrint(
            'AURA_NATIVE_YOUTUBE_SMOKE_PASSED: resolve/decode/play/position/seek/pause without WebView',
          );
        });
      } finally {
        audio.dispose();
      }
    },
    timeout: const Timeout(Duration(minutes: 2)),
  );
}
