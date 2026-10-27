import 'package:flutter_test/flutter_test.dart';
import 'package:aura/app/aura_controller.dart';
import 'package:aura/core/catalog/artist_directory.dart';
import 'package:aura/core/catalog/recording_search.dart';
import 'package:aura/features/youtube/online_track.dart';
import 'package:aura/shared/models/music.dart';

import 'fakes.dart';

DirectorySong song(int number) => DirectorySong(
  id: number,
  title: 'Traccia $number',
  artist: 'Artista',
  album: 'Disco',
  artistId: 1,
  albumId: 20,
  number: number,
  disc: 1,
  seconds: 180,
);
OnlineTrack video(int number, {String? id}) => OnlineTrack(
  id: id ?? 'video$number',
  title: 'Traccia $number',
  artist: 'Artista - Topic',
  durationSeconds: 180,
);

class _Catalog extends FakeMusicCatalog {
  bool missingTwo = false;
  @override
  Future<List<OnlineTrack>> search(String query) async {
    requests.add(query);
    for (var i = 1; i <= 3; i++) {
      if (query.contains('Traccia $i')) {
        return i == 2 && missingTwo ? [] : [video(i)];
      }
    }
    return [];
  }
}

class _ShortQueryCatalog extends FakeMusicCatalog {
  @override
  Future<List<OnlineTrack>> search(String query) async {
    requests.add(query);
    return query.contains('&') ? [] : [video(1)];
  }
}

class _RejectVideo extends FakeAudioEngine {
  @override
  Future<void> load(Track track) async {
    if (track.source == 'broken') throw StateError('unavailable upload');
    await super.load(track);
  }
}

void main() {
  test('album replaces an unrelated queue, follows order lazily and restores pending tracks', () async {
    final store = MemoryLibraryStore();
    final catalog = _Catalog();
    final audio = FakeAudioEngine();
    final c = AuraController(
      audio: audio,
      store: store,
      catalog: catalog,
      includeDemoTracks: true,
    );
    await c.initialize();
    c.shuffle = true;
    await c.playAlbumSong(song(2), [
      song(3),
      song(1),
      song(2),
    ], selected: video(2));
    expect(c.queueTracks.map((t) => t.title), [
      'Traccia 1',
      'Traccia 2',
      'Traccia 3',
    ]);
    expect(c.current.title, 'Traccia 2');
    expect(c.shuffle, isFalse);
    expect(catalog.requests, isEmpty);
    expect(c.queueTracks.first.needsRecording, isTrue);
    await c.next();
    expect(c.current.title, 'Traccia 3');
    expect(c.current.source, 'video3');
    expect(catalog.requests, ['Artista Traccia 3']);
    await c.previous();
    expect(c.current.title, 'Traccia 2');
    await c.save();
    c.dispose();
    final restored = AuraController(
      audio: FakeAudioEngine(),
      store: store,
      catalog: _Catalog(),
    );
    await restored.initialize();
    expect(restored.queueTracks.map((t) => t.title), [
      'Traccia 1',
      'Traccia 2',
      'Traccia 3',
    ]);
    await restored.previous();
    expect(restored.current.source, 'video1');
    expect(restored.libraryTracks, isEmpty);
    restored.dispose();
  });
  test(
    'automatic completion advances within album and stops at its end',
    () async {
      final audio = FakeAudioEngine();
      final c = AuraController(
        audio: audio,
        store: MemoryLibraryStore(),
        catalog: _Catalog(),
      );
      await c.initialize();
      await c.playAlbumSong(song(1), [
        song(1),
        song(2),
        song(3),
      ], selected: video(1));
      await c.next(automatic: true);
      expect(c.current.title, 'Traccia 2');
      await c.next(automatic: true);
      expect(c.current.title, 'Traccia 3');
      await c.next(automatic: true);
      expect(c.current.title, 'Traccia 3');
      expect(audio.playing, isFalse);
      c.dispose();
    },
  );
  test('an unavailable album track preserves its place and never jumps to unrelated music', () async {
    final catalog = _Catalog()..missingTwo = true;
    final c = AuraController(
      audio: FakeAudioEngine(),
      store: MemoryLibraryStore(),
      catalog: catalog,
    );
    await c.initialize();
    await c.playAlbumSong(song(1), [
      song(1),
      song(2),
      song(3),
    ], selected: video(1));
    await c.next();
    expect(c.current.title, 'Traccia 2');
    expect(c.error, contains('Traccia 2'));
    expect(c.audio.playing, isFalse);
    expect(c.queue.length, 3);
    await c.next();
    expect(c.current.title, 'Traccia 3');
    expect(c.error, isNull);
    c.dispose();
  });
  test('failed upload retries another matching recording without replacing queue IDs', () async {
    final c = AuraController(
      audio: _RejectVideo(),
      store: MemoryLibraryStore(),
      catalog: _Catalog(),
    );
    await c.initialize();
    await c.playAlbumSong(song(1), [
      song(1),
      song(2),
    ], selected: video(1, id: 'broken'));
    expect(c.current.id, 'catalog:apple:1');
    expect(c.current.source, 'video1');
    expect(c.queue, ['catalog:apple:1', 'catalog:apple:2']);
    expect(c.error, isNull);
    c.dispose();
  });
  test('alternate queries shorten credits and never substitute another performer or remix', () async {
    final seed = Track(
      id: 'catalog:1',
      title: song(1).title,
      artist: 'Artista & Ospite',
      album: 'Disco',
      source: '',
      catalogIdentity: song(1).identity,
      durationSeconds: 180,
    );
    final catalog = _ShortQueryCatalog();
    expect(await findRecordings(catalog, seed), hasLength(1));
    expect(catalog.requests, [
      'Artista & Ospite Traccia 1',
      'Artista Traccia 1',
    ]);
    expect(
      matchesRecording(
        seed,
        const OnlineTrack(
          id: 'x',
          title: 'Traccia 1 (Live)',
          artist: 'Artista',
          durationSeconds: 180,
        ),
      ),
      isFalse,
    );
    expect(
      matchesRecording(
        seed,
        const OnlineTrack(
          id: 'x',
          title: 'Traccia 1',
          artist: 'Un altro artista',
          durationSeconds: 180,
        ),
      ),
      isFalse,
    );
    expect(
      matchesRecording(
        seed,
        const OnlineTrack(
          id: 'x',
          title: 'Traccia 1',
          artist: 'Artista',
          durationSeconds: 240,
        ),
      ),
      isFalse,
    );
    expect(
      matchesRecording(
        seed,
        const OnlineTrack(
          id: 'x',
          title: 'Artista - Traccia 1 (Official Audio)',
          artist: 'Label',
          durationSeconds: 181,
        ),
      ),
      isTrue,
    );
  });
}
