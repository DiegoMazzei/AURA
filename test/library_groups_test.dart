import 'package:flutter_test/flutter_test.dart';
import 'package:aura/shared/models/music.dart';
import 'package:aura/features/library/library_groups.dart';
import 'package:aura/features/youtube/online_track.dart';
import 'package:aura/app/aura_controller.dart';
import 'package:aura/core/storage/library_store.dart';

import 'fakes.dart';

void main() {
  test('artist grouping normalizes whitespace and case', () {
    final groups = groupByArtist([
      const Track(id: 'a', title: 'One', artist: 'Daft Punk', source: 'a'),
      const Track(id: 'b', title: 'Two', artist: ' daft   punk ', source: 'b'),
    ]);
    expect(groups.single.tracks.length, 2);
  });
  test('same album title from distinct artists stays separate, missing albums are explicit', () {
    final groups = groupByAlbum([
      const Track(
        id: 'a',
        title: 'One',
        artist: 'Artist A',
        album: 'Greatest Hits',
        source: 'a',
      ),
      const Track(
        id: 'b',
        title: 'Two',
        artist: 'Artist B',
        album: 'Greatest Hits',
        source: 'b',
      ),
      const Track(id: 'c', title: 'Three', artist: 'Artist B', source: 'c'),
    ]);
    expect(groups.length, 3);
    expect(
      groups.where((g) => g.unknownAlbum).single.name,
      'Album da completare',
    );
  });
  test('YouTube heart is visible in unified favorites and survives restart and removal', () async {
    final store = MemoryLibraryStore();
    final c = AuraController(
      includeDemoTracks: true,
      audio: FakeAudioEngine(),
      store: store,
      catalog: FakeMusicCatalog(),
    );
    await c.initialize();
    const t = OnlineTrack(id: 'M7lc1UVf-VE', title: 'Track', artist: 'Artist');
    c.favoriteOnline(t);
    await c.save();
    expect(c.favorites, contains('yt:${t.id}'));
    expect(c.libraryTracks.any((t) => t.id == 'yt:M7lc1UVf-VE'), isTrue);
    final restored = AuraController(
      includeDemoTracks: true,
      audio: FakeAudioEngine(),
      store: store,
      catalog: FakeMusicCatalog(),
    );
    await restored.initialize();
    expect(restored.track('yt:${t.id}')?.isYoutube, isTrue);
    expect(restored.favorites, contains('yt:${t.id}'));
    restored.toggleFavorite('yt:${t.id}');
    await restored.save();
    final again = AuraController(
      includeDemoTracks: true,
      audio: FakeAudioEngine(),
      store: store,
      catalog: FakeMusicCatalog(),
    );
    await again.initialize();
    expect(again.favorites, isNot(contains('yt:${t.id}')));
    expect(again.onlineFavorites, isNot(contains(t.id)));
    again.dispose();
    restored.dispose();
    c.dispose();
  });
  test(
    'manual artist album edits survive restart and regroup the library',
    () async {
      final store = MemoryLibraryStore();
      final c = AuraController(
        includeDemoTracks: true,
        audio: FakeAudioEngine(),
        store: store,
      );
      await c.initialize();
      c.updateTrackMetadata(
        c.current,
        title: 'Orbita',
        artist: 'New Artist',
        album: 'New Album',
      );
      await c.save();
      final other = AuraController(
        includeDemoTracks: true,
        audio: FakeAudioEngine(),
        store: store,
      );
      await other.initialize();
      expect(other.current.artist, 'New Artist');
      expect(other.current.album, 'New Album');
      expect(other.current.metadataEdited, isTrue);
      expect(
        groupByArtist(other.libraryTracks).any((g) => g.name == 'New Artist'),
        isTrue,
      );
      other.dispose();
      c.dispose();
    },
  );
  test(
    'local metadata reader handles a real WAV without inventing missing tags',
    () async {
      final tags = await readLocalTrackTags('assets/audio/orbita.wav');
      expect(tags['duration'], 40);
      expect(tags['album'], isNull);
    },
  );
}
