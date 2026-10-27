import 'catalog_identity.dart';
import 'music_json_client.dart';
import 'musicbrainz_catalog.dart' show normalizeMusicText;

class DirectoryArtist {
  const DirectoryArtist({
    required this.id,
    required this.name,
    this.genre = '',
  });
  final int id;
  final String name, genre;
  Map<String, dynamic> toJson() => {'id': id, 'name': name, 'genre': genre};
  factory DirectoryArtist.fromJson(Map<String, dynamic> j) => DirectoryArtist(
    id: (j['id'] as num).toInt(),
    name: j['name'] as String,
    genre: j['genre'] as String? ?? '',
  );
}

class DirectoryAlbum {
  const DirectoryAlbum({
    required this.id,
    required this.artistId,
    required this.title,
    required this.artist,
    required this.year,
    required this.trackCount,
    this.releaseDate,
  });
  final int id, artistId, year, trackCount;
  final String title, artist;
  final DateTime? releaseDate;
}

class DirectorySong {
  const DirectorySong({
    required this.id,
    required this.title,
    required this.artist,
    required this.album,
    required this.artistId,
    required this.albumId,
    required this.number,
    required this.disc,
    required this.seconds,
    this.credits = const [],
    this.albumArtist = '',
    this.albumArtistId,
  });
  final int id, artistId, albumId, number, disc, seconds;
  final String title, artist, album, albumArtist;
  final List<CatalogArtist> credits;
  final int? albumArtistId;
  CatalogIdentity get identity => CatalogIdentity(
    recordingId: 'apple:$id',
    provider: 'Apple',
    title: title,
    artists: credits.isEmpty
        ? [CatalogArtist(id: 'apple:$artistId', name: artist)]
        : credits,
    releaseGroupId: 'apple:$albumId',
    album: album,
    albumArtistId: 'apple:${albumArtistId ?? artistId}',
    albumArtist: albumArtist.isEmpty ? artist : albumArtist,
  );
}

class DirectoryResults {
  const DirectoryResults({
    this.artists = const [],
    this.albums = const [],
    this.songs = const [],
  });
  final List<DirectoryArtist> artists;
  final List<DirectoryAlbum> albums;
  final List<DirectorySong> songs;
}

abstract class ArtistDirectory {
  Future<DirectoryResults> search(String query);
  Future<List<DirectoryArtist>> searchArtists(String query);
  Future<List<DirectoryAlbum>> albums(DirectoryArtist artist);
  Future<List<DirectorySong>> songs(DirectoryAlbum album);
}

/// Factual catalog data only. No Apple previews or promotional artwork.
class AppleArtistDirectory implements ArtistDirectory {
  AppleArtistDirectory(this.client);
  final MusicJsonClient client;
  final Map<String, Object> _cache = {};
  Future<Object?> _get(String path, Map<String, String> args) async {
    final uri = Uri.https('itunes.apple.com', path, {'country': 'IT', ...args});
    final key = uri.toString();
    if (_cache.containsKey(key)) return _cache[key];
    final data = await client.get(uri);
    if (data != null) {
      if (_cache.length >= 100) _cache.remove(_cache.keys.first);
      _cache[key] = data;
    }
    return data;
  }

  List<Map> _rows(Object? data) => data is Map && data['results'] is List
      ? (data['results'] as List).whereType<Map>().toList()
      : [];
  DirectoryResults _parse(Object? data) {
    final rows = _rows(data);
    final known = <int, String>{
      for (final r in rows)
        if (r['wrapperType'] == 'artist' &&
            r['artistId'] is num &&
            r['artistName'] is String)
          (r['artistId'] as num).toInt(): r['artistName'] as String,
    };
    final artists = <int, DirectoryArtist>{};
    final albums = <int, DirectoryAlbum>{};
    final songs = <int, DirectorySong>{};
    for (final j in rows) {
      if (j['artistId'] is! num) continue;
      final aid = (j['artistId'] as num).toInt();
      final name = j['artistName'] as String? ?? '';
      if (j['wrapperType'] == 'artist') {
        artists[aid] = DirectoryArtist(
          id: aid,
          name: name,
          genre: j['primaryGenreName'] as String? ?? '',
        );
      }
      if (j['collectionId'] is! num) continue;
      final cid = (j['collectionId'] as num).toInt();
      if (j['wrapperType'] == 'collection') {
        albums[cid] = DirectoryAlbum(
          id: cid,
          artistId: aid,
          title: j['collectionName'] as String? ?? '',
          artist: name,
          year: DateTime.tryParse(j['releaseDate'] as String? ?? '')?.year ?? 0,
          releaseDate: DateTime.tryParse(j['releaseDate'] as String? ?? ''),
          trackCount: (j['trackCount'] as num?)?.toInt() ?? 0,
        );
      }
      if (j['kind'] == 'song' && j['trackId'] is num) {
        final id = (j['trackId'] as num).toInt();
        songs[id] = DirectorySong(
          id: id,
          title: j['trackName'] as String? ?? '',
          artist: name,
          album: j['collectionName'] as String? ?? '',
          artistId: aid,
          albumId: cid,
          number: (j['trackNumber'] as num?)?.toInt() ?? 0,
          disc: (j['discNumber'] as num?)?.toInt() ?? 1,
          seconds: ((j['trackTimeMillis'] as num? ?? 0) / 1000).round(),
          credits: _credits(j, known),
          albumArtist: known[aid] ?? name,
          albumArtistId: aid,
        );
      }
    }
    return DirectoryResults(
      artists: artists.values.toList(),
      albums: albums.values.toList(),
      songs: songs.values.toList(),
    );
  }

  @override
  Future<DirectoryResults> search(String query) async => _parse(
    await _get('/search', {
      'term': query.trim(),
      'media': 'music',
      'entity': 'musicArtist,album,song',
      'limit': '100',
    }),
  );
  @override
  Future<List<DirectoryArtist>> searchArtists(String query) async =>
      (await search(query)).artists;
  @override
  Future<List<DirectoryAlbum>> albums(DirectoryArtist artist) async {
    final rows = _rows(
      await _get('/lookup', {
        'id': '${artist.id}',
        'entity': 'album',
        'limit': '200',
      }),
    );
    final unique = <int, DirectoryAlbum>{};
    for (final j in rows) {
      if (j['wrapperType'] != 'collection' ||
          j['collectionId'] is! num ||
          j['artistId'] is! num) {
        continue;
      }
      final id = (j['collectionId'] as num).toInt();
      unique[id] = DirectoryAlbum(
        id: id,
        artistId: (j['artistId'] as num).toInt(),
        title: j['collectionName'] as String? ?? '',
        artist: j['artistName'] as String? ?? artist.name,
        year: DateTime.tryParse(j['releaseDate'] as String? ?? '')?.year ?? 0,
        releaseDate: DateTime.tryParse(j['releaseDate'] as String? ?? ''),
        trackCount: (j['trackCount'] as num?)?.toInt() ?? 0,
      );
    }
    return unique.values
        .where(
          (a) =>
              a.artistId == artist.id ||
              (' ${normalizeMusicText(a.artist)} ').contains(
                ' ${normalizeMusicText(artist.name)} ',
              ),
        )
        .toList()
      ..sort((a, b) => b.year.compareTo(a.year));
  }

  @override
  Future<List<DirectorySong>> songs(DirectoryAlbum album) async {
    final result = <DirectorySong>[];
    for (final j in _rows(
      await _get('/lookup', {
        'id': '${album.id}',
        'entity': 'song',
        'limit': '200',
      }),
    )) {
      if (j['kind'] != 'song' ||
          j['trackId'] is! num ||
          j['collectionId'] != album.id) {
        continue;
      }
      result.add(
        DirectorySong(
          id: (j['trackId'] as num).toInt(),
          title: j['trackName'] as String? ?? '',
          artist: j['artistName'] as String? ?? album.artist,
          album: album.title,
          artistId: (j['artistId'] as num?)?.toInt() ?? album.artistId,
          albumId: album.id,
          number: (j['trackNumber'] as num?)?.toInt() ?? 0,
          disc: (j['discNumber'] as num?)?.toInt() ?? 1,
          seconds: ((j['trackTimeMillis'] as num? ?? 0) / 1000).round(),
          credits: _credits(j, {album.artistId: album.artist}),
          albumArtist: album.artist,
          albumArtistId: album.artistId,
        ),
      );
    }
    result.sort(
      (a, b) => a.disc != b.disc
          ? a.disc.compareTo(b.disc)
          : a.number.compareTo(b.number),
    );
    return result;
  }
}

List<CatalogArtist> _credits(Map row, Map<int, String> known) {
  final aid = (row['artistId'] as num?)?.toInt() ?? 0;
  final raw = row['artistName'] as String? ?? '';
  List<String> split(String text) => text
      .split(RegExp(r',\s*|\s+(?:&|x|and)\s+', caseSensitive: false))
      .map((s) => s.trim())
      .where((s) => s.isNotEmpty)
      .toList();
  final names = split(raw);
  final knownName = known[aid];
  // A collaborative album credit is not the performer of every track.
  final primary =
      knownName != null &&
          names.any(
            (n) => normalizeMusicText(n) == normalizeMusicText(knownName),
          )
      ? knownName
      : names.firstOrNull ?? raw;
  final title = row['trackName'] as String? ?? '';
  final feature = RegExp(
    r'[\[(](?:feat\.?|ft\.?|featuring)\s+([^\])]+)',
    caseSensitive: false,
  ).firstMatch(title)?.group(1);
  final all = <String>[
    primary,
    ...names,
    if (feature != null) ...split(feature),
  ];
  final unique = <String, CatalogArtist>{};
  for (final name in all) {
    final normalized = normalizeMusicText(name);
    if (normalized.isEmpty) continue;
    int? id = normalized == normalizeMusicText(primary) ? aid : null;
    for (final entry in known.entries) {
      if (normalizeMusicText(entry.value) == normalized) id = entry.key;
    }
    unique[normalized] = CatalogArtist(
      id: id == null ? 'credit:$normalized' : 'apple:$id',
      name: name,
    );
  }
  return unique.values.toList();
}
