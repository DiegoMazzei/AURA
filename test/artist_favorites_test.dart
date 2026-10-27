import 'package:flutter_test/flutter_test.dart';
import 'package:aura/app/aura_controller.dart';
import 'package:aura/core/catalog/artist_directory.dart';
import 'package:aura/shared/models/music.dart';

import 'fakes.dart';

void main() {
  test('listening keeps online music in history without saving songs or following artists', () async {
    final c = AuraController(
      audio: FakeAudioEngine(),
      store: MemoryLibraryStore(),
    );
    await c.initialize();
    const song = Track(
      id: 'yt:abcdefghijk',
      title: 'Una canzone',
      artist: 'Gemitaiz',
      source: 'abcdefghijk',
      isYoutube: true,
    );
    c.tracks.add(song);
    await c.playTrack(song);
    expect(c.recent, [song.id]);
    expect(c.libraryTracks, isEmpty);
    expect(c.favoriteArtists, isEmpty);
    c.toggleFavorite(song.id);
    expect(c.libraryTracks.map((t) => t.id), [song.id]);
    expect(c.favoriteArtists, isEmpty);
    c.toggleFavorite(song.id);
    expect(c.libraryTracks, isEmpty);
    c.dispose();
  });
  test('artist favorites survive restart independently of songs, and can be removed', () async {
    final store = MemoryLibraryStore();
    final c = AuraController(audio: FakeAudioEngine(), store: store);
    await c.initialize();
    const artist = DirectoryArtist(
      id: 441911933,
      name: 'Gemitaiz',
      genre: 'Hip-Hop/Rap',
    );
    c.toggleArtistFavorite(artist);
    await c.save();
    c.dispose();
    final restored = AuraController(audio: FakeAudioEngine(), store: store);
    await restored.initialize();
    expect(restored.favoriteArtists[artist.id]?.name, artist.name);
    expect(restored.libraryTracks, isEmpty);
    restored.toggleArtistFavorite(artist);
    await restored.save();
    expect((store.data!['favoriteArtists'] as List), isEmpty);
    restored.dispose();
  });
}
