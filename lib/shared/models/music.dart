import '../../core/catalog/catalog_identity.dart';

class LyricLine {
  const LyricLine(this.at, this.text);
  final Duration at;
  final String text;
}

class Track {
  const Track({
    required this.id,
    required this.title,
    required this.artist,
    required this.source,
    this.isAsset = false,
    this.isYoutube = false,
    this.album = '',
    this.catalogIdentity,
    this.plainLyrics = '',
    this.lyricsSource = '',
    this.lyricsSourceUrl = '',
    this.metadataEdited = false,
    this.color = 0xff829bff,
    this.durationSeconds = 0,
    this.lyrics = const [],
  });
  final String id, title, artist, source;
  final bool isAsset, isYoutube, metadataEdited;
  final String album;
  final CatalogIdentity? catalogIdentity;
  final String plainLyrics, lyricsSource, lyricsSourceUrl;
  bool get needsRecording =>
      isYoutube && source.isEmpty && catalogIdentity != null;
  String? get artworkUrl => isYoutube && source.isNotEmpty
      ? 'https://i.ytimg.com/vi/$source/hqdefault.jpg'
      : catalogIdentity?.artworkUrl;
  final int color, durationSeconds;
  final List<LyricLine> lyrics;
  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'artist': artist,
    'source': source,
    'isYoutube': isYoutube,
    'album': album,
    'catalogIdentity': catalogIdentity?.toJson(),
    'plainLyrics': plainLyrics,
    'lyricsSource': lyricsSource,
    'lyricsSourceUrl': lyricsSourceUrl,
    'metadataEdited': metadataEdited,
    'color': color,
    'durationSeconds': durationSeconds,
    'lyrics': lyrics
        .map((l) => {'ms': l.at.inMilliseconds, 'text': l.text})
        .toList(),
  };
  factory Track.fromJson(Map<String, dynamic> j) => Track(
    id: j['id'] as String,
    title: j['title'] as String,
    artist: j['artist'] as String,
    source: j['source'] as String,
    isYoutube: j['isYoutube'] == true,
    album: j['album'] as String? ?? '',
    catalogIdentity: j['catalogIdentity'] is Map
        ? CatalogIdentity.fromJson(
            Map<String, dynamic>.from(j['catalogIdentity']),
          )
        : null,
    plainLyrics: j['plainLyrics'] as String? ?? '',
    lyricsSource: j['lyricsSource'] as String? ?? '',
    lyricsSourceUrl: j['lyricsSourceUrl'] as String? ?? '',
    metadataEdited: j['metadataEdited'] == true,
    color: (j['color'] as num?)?.toInt() ?? 0xff829bff,
    durationSeconds: (j['durationSeconds'] as num?)?.toInt() ?? 0,
    lyrics: (j['lyrics'] as List? ?? [])
        .map(
          (l) => LyricLine(
            Duration(milliseconds: (l['ms'] as num).toInt()),
            l['text'] as String,
          ),
        )
        .toList(),
  );
  Track withLyrics(List<LyricLine> lines) => copyWith(lyrics: lines);
  Track copyWith({
    String? title,
    String? source,
    String? artist,
    String? album,
    int? durationSeconds,
    bool? metadataEdited,
    List<LyricLine>? lyrics,
    CatalogIdentity? catalogIdentity,
    bool clearCatalog = false,
    String? plainLyrics,
    String? lyricsSource,
    String? lyricsSourceUrl,
  }) => Track(
    id: id,
    title: title ?? this.title,
    artist: artist ?? this.artist,
    album: album ?? this.album,
    source: source ?? this.source,
    isAsset: isAsset,
    isYoutube: isYoutube,
    color: color,
    durationSeconds: durationSeconds ?? this.durationSeconds,
    metadataEdited: metadataEdited ?? this.metadataEdited,
    lyrics: lyrics ?? this.lyrics,
    catalogIdentity: clearCatalog
        ? null
        : catalogIdentity ?? this.catalogIdentity,
    plainLyrics: plainLyrics ?? this.plainLyrics,
    lyricsSource: lyricsSource ?? this.lyricsSource,
    lyricsSourceUrl: lyricsSourceUrl ?? this.lyricsSourceUrl,
  );
}

class AuraPlaylist {
  AuraPlaylist({required this.id, required this.name, List<String>? trackIds})
    : trackIds = List.of(trackIds ?? []);
  final String id;
  String name;
  final List<String> trackIds;
  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'trackIds': trackIds,
  };
  factory AuraPlaylist.fromJson(Map<String, dynamic> j) => AuraPlaylist(
    id: j['id'] as String,
    name: j['name'] as String,
    trackIds: List<String>.from(j['trackIds'] as List),
  );
}

const demoTracks = [
  Track(
    id: 'aura-orbit',
    title: 'Orbita',
    artist: 'AURA Studio',
    album: 'AURA Originals',
    source: 'assets/audio/orbita.wav',
    isAsset: true,
    color: 0xff78adff,
    durationSeconds: 40,
    lyrics: [
      LyricLine(Duration.zero, 'Lascia il rumore lontano'),
      LyricLine(Duration(seconds: 8), 'segui la luce che va.'),
      LyricLine(Duration(seconds: 16), 'Siamo polvere e suono,'),
      LyricLine(Duration(seconds: 24), 'un universo che sa'),
      LyricLine(Duration(seconds: 32), 'dove la notte ci porta.'),
    ],
  ),
  Track(
    id: 'aura-afterglow',
    title: 'Afterglow',
    artist: 'AURA Studio',
    album: 'AURA Originals',
    source: 'assets/audio/afterglow.wav',
    isAsset: true,
    color: 0xffe9a0cd,
    durationSeconds: 40,
  ),
];

/// LRC supplied by the user. Supports multiple timestamps and global offsets.
List<LyricLine> parseLrc(String input) {
  final result = <LyricLine>[];
  final offset =
      int.tryParse(
        RegExp(r'\[offset:([+-]?\d+)\]').firstMatch(input)?.group(1) ?? '',
      ) ??
      0;
  final stamp = RegExp(r'\[(\d{1,3}):(\d{2})(?:[.:](\d{1,3}))?\]');
  for (final row in input.split('\n')) {
    final matches = stamp.allMatches(row).toList();
    if (matches.isEmpty) continue;
    final text = row.substring(matches.last.end).trim();
    if (text.isEmpty) continue;
    for (final m in matches) {
      final seconds = int.parse(m[2]!);
      if (seconds >= 60) continue;
      final fraction = (m[3] ?? '').padRight(3, '0');
      final ms =
          int.parse(m[1]!) * 60000 +
          seconds * 1000 +
          int.parse(fraction) +
          offset;
      result.add(LyricLine(Duration(milliseconds: ms < 0 ? 0 : ms), text));
    }
  }
  result.sort((a, b) => a.at.compareTo(b.at));
  return result;
}
