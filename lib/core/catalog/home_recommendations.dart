import 'artist_directory.dart';
import 'musicbrainz_catalog.dart' show normalizeMusicText;
import '../../shared/models/music.dart';

class TasteSeed {
  const TasteSeed(this.name, {this.id, this.score = 0});
  final String name;
  final int? id;
  final double score;
}

List<TasteSeed> homeTaste({
  required Iterable<DirectoryArtist> followed,
  required List<Track> recent,
  required Iterable<Track> favorites,
}) {
  final seeds = <String, TasteSeed>{};
  void add(String name, int? id, double weight) {
    final key = normalizeMusicText(name);
    if (key.isEmpty || key == 'artista sconosciuto') return;
    final old = seeds[key];
    seeds[key] = TasteSeed(
      name,
      id: id ?? old?.id,
      score: (old?.score ?? 0) + weight,
    );
  }

  void fromTrack(Track t, double weight) {
    final credit = t.catalogIdentity?.artists.firstOrNull;
    final name = credit?.name ?? t.artist;
    final id = credit?.id ?? '';
    add(
      name,
      id.startsWith('apple:') ? int.tryParse(id.substring(6)) : null,
      weight,
    );
  }

  for (final artist in followed) {
    add(artist.name, artist.id, 12);
  }
  for (var i = 0; i < recent.take(20).length; i++) {
    fromTrack(recent[i], 8 / (i + 1));
  }
  for (final track in favorites.take(30)) {
    fromTrack(track, 2);
  }
  return seeds.values.toList()..sort((a, b) => b.score.compareTo(a.score));
}

String homeSongKey(String title, String artist) =>
    '${normalizeMusicText(artist)}:${normalizeMusicText(title)}';

/// Emits partial results so one slow artist does not hide all recommendations.
class HomeRecommendations {
  HomeRecommendations(this.directory);
  final ArtistDirectory directory;
  Stream<DirectoryResults> watch(
    List<TasteSeed> seeds, {
    Set<String> heard = const {},
  }) async* {
    final albums = <DirectoryAlbum>[];
    final songs = <DirectorySong>[];
    final songKeys = <String>{};
    var success = false;
    for (final seed in seeds.take(3)) {
      DirectoryResults data;
      try {
        data = await directory
            .search(seed.name)
            .timeout(const Duration(seconds: 18));
      } catch (_) {
        continue;
      }
      success = true;
      bool matches(int id, String name) =>
          seed.id == id ||
          normalizeMusicText(name) == normalizeMusicText(seed.name);
      albums.addAll(
        data.albums.where((a) => matches(a.artistId, a.artist)).take(3),
      );
      for (final song
          in data.songs.where((s) => matches(s.artistId, s.artist)).take(12)) {
        final key = homeSongKey(song.title, song.artist);
        if (heard.contains(key) || !songKeys.add(key)) continue;
        songs.add(song);
        if (songs.where((s) => matches(s.artistId, s.artist)).length >= 4) {
          break;
        }
      }
      yield DirectoryResults(
        albums: deduplicateAlbums(albums).take(9).toList(),
        songs: List.of(songs.take(12)),
      );
    }
    if (!success && seeds.isNotEmpty) {
      throw StateError('Recommendations unavailable');
    }
  }
}
