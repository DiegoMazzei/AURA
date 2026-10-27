import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:aura/app/aura_controller.dart';
import 'package:aura/shared/models/music.dart';

import 'fakes.dart';

void main() {
  late FakeAudioEngine audio;
  late MemoryLibraryStore store;
  late AuraController c;
  setUp(() async {
    audio = FakeAudioEngine();
    store = MemoryLibraryStore();
    c = AuraController(audio: audio, store: store);
    await c.initialize();
  });
  tearDown(() => c.dispose());
  test('play pause seek and next use the same engine', () async {
    await c.togglePlayback();
    expect(audio.loadedId, 'aura-orbit');
    expect(audio.playing, isTrue);
    await c.seek(const Duration(seconds: 9));
    expect(audio.position.inSeconds, 9);
    await c.togglePlayback();
    expect(audio.playing, isFalse);
    await c.next();
    expect(c.currentId, 'aura-afterglow');
    expect(audio.playing, isTrue);
    audio.advance(const Duration(seconds: 5));
    await c.previous();
    expect(audio.position, Duration.zero);
    await c.previous();
    expect(c.currentId, 'aura-orbit');
  });
  test(
    'end of queue stops, repeat all wraps and repeat one restarts',
    () async {
      await c.playTrack(demoTracks.last);
      await audio.complete();
      expect(audio.playing, isFalse);
      c.cycleRepeat();
      await c.playTrack(demoTracks.last);
      await audio.complete();
      expect(c.currentId, 'aura-orbit');
      expect(audio.playing, isTrue);
      c.cycleRepeat();
      await c.playTrack(demoTracks.last);
      await audio.complete();
      expect(c.currentId, 'aura-afterglow');
      expect(audio.position, Duration.zero);
      expect(audio.playing, isTrue);
    },
  );
  test('retry after a stream failure resolves the source again', () async {
    await c.playTrack(demoTracks.first);
    expect(audio.loadCount, 1);
    await audio.pause();
    audio.error = 'expired remote source';
    audio.notifyListeners();
    await c.playTrack(demoTracks.first);
    expect(audio.loadCount, 2);
    expect(audio.error, isNull);
    expect(c.error, isNull);
    expect(audio.playing, isTrue);
  });
  test('shuffle avoids current track when alternatives exist', () async {
    c.toggleShuffle();
    await c.playTrack(demoTracks.first);
    await c.next();
    expect(c.currentId, demoTracks.last.id);
    expect(c.queue.toSet().length, c.queue.length);
  });
  test('queue and playlist reorder use post-removal destination indices', () {
    c.reorderQueue(0, 1);
    expect(c.queue.first, 'aura-afterglow');
    final p = c.createPlaylist('Notte');
    c.addToPlaylist(p, demoTracks.first.id);
    c.addToPlaylist(p, demoTracks.last.id);
    c.addToPlaylist(p, demoTracks.last.id);
    expect(p.trackIds.length, 2);
    c.reorderPlaylist(p, 0, 1);
    expect(p.trackIds.first, demoTracks.last.id);
    c.removeFromPlaylist(p, demoTracks.last.id);
    expect(p.trackIds, [demoTracks.first.id]);
    c.renamePlaylist(p, 'Alba');
    expect(p.name, 'Alba');
    c.deletePlaylist(p);
    expect(c.playlists, isEmpty);
  });
  test('library favorites playlist theme queue and paused position survive restart', () async {
    store.imported = [
      const Track(
        id: 'local',
        title: 'Local',
        artist: 'Me',
        source: 'audio/local.wav',
      ),
    ];
    await c.importAudio();
    c.toggleFavorite('local');
    final p = c.createPlaylist('Viaggio');
    c.addToPlaylist(p, 'local');
    c.setTheme(ThemeMode.light);
    await c.playTrack(c.track('local')!);
    await c.seek(const Duration(seconds: 12));
    await c.save();
    final otherAudio = FakeAudioEngine();
    final restored = AuraController(audio: otherAudio, store: store);
    await restored.initialize();
    expect(restored.track('local')?.title, 'Local');
    expect(restored.favorites, contains('local'));
    expect(restored.playlists.single.trackIds, ['local']);
    expect(restored.themeMode, ThemeMode.light);
    expect(restored.currentId, 'local');
    expect(restored.position.inSeconds, 12);
    expect(otherAudio.playing, isFalse);
    await restored.togglePlayback();
    expect(otherAudio.position.inSeconds, 12);
    restored.dispose();
  });
  test(
    'engine failure remains recoverable and never claims playback',
    () async {
      audio.failLoad = true;
      await c.togglePlayback();
      expect(c.error, isNotNull);
      expect(audio.playing, isFalse);
      expect(c.busy, isFalse);
      audio.failLoad = false;
      await c.togglePlayback();
      expect(audio.playing, isTrue);
      expect(c.error, isNull);
    },
  );
  test('read write and import failures are visible without crashing', () async {
    store.failWrite = true;
    c.toggleFavorite(c.currentId);
    await c.save();
    expect(c.error, contains('Salvataggio'));
    store.failImport = true;
    await c.importAudio();
    expect(c.error, contains('Importazione'));
    expect(c.importing, isFalse);
  });
  test('LRC attaches to track, persists and rejects missing timing', () async {
    store.lrc = '[00:00.00]Una luce\n[00:05.12]Nella notte';
    await c.importLyrics(c.current);
    expect(c.current.lyrics.length, 2);
    expect(c.current.lyrics.last.at.inMilliseconds, 5120);
    store.lrc = 'plain text';
    await c.importLyrics(c.current);
    expect(c.error, contains('tempi validi'));
    expect(c.current.lyrics.length, 2);
  });
  test('LRC supports offsets multiple tags and ignores metadata', () {
    final lines = parseLrc(
      '[ar:AURA]\n[offset:-200]\n[00:01.2][00:03.045]Luce\n[00:99]invalid\n[00:00]Alba',
    );
    expect(lines.map((v) => v.at.inMilliseconds), [0, 1000, 2845]);
    expect(lines.first.text, 'Alba');
  });
}
