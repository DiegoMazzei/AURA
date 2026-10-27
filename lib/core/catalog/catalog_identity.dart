class CatalogArtist {
  const CatalogArtist({required this.id, required this.name});
  final String id, name;
  Map<String, dynamic> toJson() => {'id': id, 'name': name};
  factory CatalogArtist.fromJson(Map<String, dynamic> j) =>
      CatalogArtist(id: j['id'] as String, name: j['name'] as String);
}

class CatalogIdentity {
  const CatalogIdentity({
    required this.recordingId,
    required this.artists,
    this.provider = 'MusicBrainz',
    this.catalogUrl = '',
    this.releaseGroupId = '',
    this.releaseId = '',
    this.albumArtistId = '',
    this.albumArtist = '',
    this.album = '',
    this.title = '',
  });
  final String provider, catalogUrl;
  final String recordingId,
      releaseGroupId,
      releaseId,
      albumArtistId,
      albumArtist,
      album,
      title;
  final List<CatalogArtist> artists;
  String get sourceUrl => catalogUrl.isNotEmpty
      ? catalogUrl
      : 'https://musicbrainz.org/recording/$recordingId';
  String? get artworkUrl => provider != 'MusicBrainz' || releaseId.isEmpty
      ? null
      : 'https://coverartarchive.org/release/$releaseId/front-500';
  Map<String, dynamic> toJson() => {
    'provider': provider,
    'catalogUrl': catalogUrl,
    'recordingId': recordingId,
    'releaseGroupId': releaseGroupId,
    'releaseId': releaseId,
    'albumArtistId': albumArtistId,
    'albumArtist': albumArtist,
    'album': album,
    'title': title,
    'artists': artists.map((a) => a.toJson()).toList(),
  };
  factory CatalogIdentity.fromJson(Map<String, dynamic> j) => CatalogIdentity(
    recordingId: j['recordingId'] as String,
    provider: j['provider'] as String? ?? 'MusicBrainz',
    catalogUrl: j['catalogUrl'] as String? ?? '',
    releaseGroupId: j['releaseGroupId'] as String? ?? '',
    releaseId: j['releaseId'] as String? ?? '',
    albumArtistId: j['albumArtistId'] as String? ?? '',
    albumArtist: j['albumArtist'] as String? ?? '',
    album: j['album'] as String? ?? '',
    title: j['title'] as String? ?? '',
    artists: (j['artists'] as List? ?? [])
        .map((a) => CatalogArtist.fromJson(Map<String, dynamic>.from(a)))
        .toList(),
  );
}
