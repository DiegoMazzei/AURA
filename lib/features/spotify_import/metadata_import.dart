import 'dart:convert';

class ImportedSong {
  const ImportedSong({
    required this.title,
    required this.artist,
    this.album = '',
    this.uri = '',
    this.durationSeconds = 0,
  });
  final String title, artist, album, uri;
  final int durationSeconds;
  String get identity =>
      '${artist.trim().toLowerCase()}::${title.trim().toLowerCase()}::${album.trim().toLowerCase()}';
  Map<String, dynamic> toJson() => {
    'title': title,
    'artist': artist,
    'album': album,
    'uri': uri,
    'durationSeconds': durationSeconds,
  };
  factory ImportedSong.fromJson(Map<String, dynamic> j) => ImportedSong(
    title: j['title'] as String,
    artist: j['artist'] as String,
    album: j['album'] as String? ?? '',
    uri: j['uri'] as String? ?? '',
    durationSeconds: (j['durationSeconds'] as num?)?.toInt() ?? 0,
  );
  Uri get youtubeSearch => Uri.https('www.youtube.com', '/results', {
    'search_query': '$title $artist',
  });
}

class ImportedCollection {
  const ImportedCollection({
    required this.name,
    required this.songs,
    this.sourceId = '',
  });
  final String name;
  final String sourceId;
  final List<ImportedSong> songs;
  String get identity => '$name::${songs.map((s) => s.identity).join('|')}';
  Map<String, dynamic> toJson() => {
    'name': name,
    'sourceId': sourceId,
    'songs': songs.map((s) => s.toJson()).toList(),
  };
  factory ImportedCollection.fromJson(Map<String, dynamic> j) =>
      ImportedCollection(
        name: j['name'] as String,
        sourceId: j['sourceId'] as String? ?? '',
        songs: (j['songs'] as List)
            .map(
              (s) => ImportedSong.fromJson(Map<String, dynamic>.from(s as Map)),
            )
            .toList(),
      );
}

/// Imports only music metadata; unrelated fields from an account export are discarded.
List<ImportedCollection> parseMusicExport(String source) {
  final input = source.replaceFirst('\ufeff', '').trim();
  if (input.isEmpty) throw const FormatException('File vuoto');
  if (!input.startsWith('{') && !input.startsWith('[')) {
    return _csvCollections(input);
  }
  final decoded = jsonDecode(input);
  ImportedSong? song(dynamic raw) {
    if (raw is! Map) return null;
    final j = raw['track'] is Map ? raw['track'] as Map : raw;
    String value(List<String> keys) {
      for (final key in keys) {
        final v = j[key];
        if (v is String && v.trim().isNotEmpty) return v.trim();
      }
      return '';
    }

    final title = value([
      'trackName',
      'name',
      'title',
      'master_metadata_track_name',
    ]);
    var artist = value([
      'artistName',
      'artist',
      'master_metadata_album_artist_name',
    ]);
    if (artist.isEmpty && j['artists'] is List) {
      artist = (j['artists'] as List)
          .whereType<Map>()
          .map((a) => a['name'])
          .whereType<String>()
          .join(', ');
    }
    if (title.isEmpty || artist.isEmpty) return null;
    var album = value([
      'albumName',
      'album',
      'master_metadata_album_album_name',
    ]);
    if (album.isEmpty && j['album'] is Map) {
      album = (j['album'] as Map)['name'] as String? ?? '';
    }
    return ImportedSong(
      title: title,
      artist: artist,
      album: album,
      uri: value(['trackUri', 'uri', 'spotify_track_uri']),
    );
  }

  List<ImportedSong> songs(dynamic list) {
    if (list is! List) return [];
    final seen = <String>{};
    return list
        .map(song)
        .whereType<ImportedSong>()
        .where((s) => seen.add(s.identity))
        .toList();
  }

  final result = <ImportedCollection>[];
  if (decoded is Map && decoded['playlists'] is List) {
    for (final p in decoded['playlists'] as List) {
      if (p is! Map) continue;
      final items = p['items'] ?? p['tracks'];
      final rows = songs(items is Map ? items['items'] : items);
      if (rows.isNotEmpty) {
        result.add(
          ImportedCollection(
            name: (p['name'] as String?)?.trim().isNotEmpty == true
                ? p['name'] as String
                : 'Playlist importata',
            songs: rows,
          ),
        );
      }
    }
  } else {
    final raw = decoded is Map
        ? decoded['tracks'] ?? decoded['items']
        : decoded;
    final rows = songs(raw);
    if (rows.isNotEmpty) {
      result.add(ImportedCollection(name: 'Musica importata', songs: rows));
    }
  }
  if (result.isEmpty) throw const FormatException('Nessun brano riconosciuto');
  return result;
}

List<ImportedCollection> _csvCollections(String input) {
  final firstLine = input.split('\n').first;
  final delimiter = firstLine.contains(';') && !firstLine.contains(',')
      ? ';'
      : ',';
  final rows = <List<String>>[];
  var row = <String>[];
  var field = StringBuffer();
  var quoted = false;
  for (var i = 0; i < input.length; i++) {
    final ch = input[i];
    if (ch == '"') {
      if (quoted && i + 1 < input.length && input[i + 1] == '"') {
        field.write('"');
        i++;
      } else {
        quoted = !quoted;
      }
    } else if (!quoted && ch == delimiter) {
      row.add(field.toString().trim());
      field = StringBuffer();
    } else if (!quoted && ch == '\n') {
      row.add(field.toString().trim());
      rows.add(row);
      row = [];
      field = StringBuffer();
    } else if (ch != '\r') {
      field.write(ch);
    }
  }
  if (quoted) throw const FormatException('Virgolette CSV non chiuse');
  row.add(field.toString().trim());
  rows.add(row);
  if (rows.length < 2) throw const FormatException('CSV senza brani');
  final headers = rows.first
      .map((s) => s.toLowerCase().replaceAll(RegExp('[^a-z]'), ''))
      .toList();
  int column(List<String> aliases) => headers.indexWhere(aliases.contains);
  final title = column(['trackname', 'title', 'name', 'brano']);
  final artist = column([
    'artistname',
    'artists',
    'artistnames',
    'artist',
    'artista',
  ]);
  final album = column(['albumname', 'album']);
  final playlist = column(['playlistname', 'playlist']);
  if (title < 0 || artist < 0) {
    throw const FormatException('Servono colonne title e artist');
  }
  final grouped = <String, List<ImportedSong>>{};
  final seen = <String, Set<String>>{};
  for (final row in rows.skip(1)) {
    String at(int i) => i >= 0 && i < row.length ? row[i].trim() : '';
    if (at(title).isEmpty || at(artist).isEmpty) continue;
    final name = at(playlist).isEmpty ? 'Musica importata' : at(playlist);
    final s = ImportedSong(
      title: at(title),
      artist: at(artist),
      album: at(album),
    );
    if ((seen[name] ??= {}).add(s.identity)) (grouped[name] ??= []).add(s);
  }
  if (grouped.isEmpty) throw const FormatException('Nessun brano riconosciuto');
  return grouped.entries
      .map((e) => ImportedCollection(name: e.key, songs: e.value))
      .toList();
}
