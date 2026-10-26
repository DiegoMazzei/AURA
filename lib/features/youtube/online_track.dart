class OnlineTrack {
  const OnlineTrack({
    required this.id,
    required this.title,
    required this.artist,
    this.durationSeconds = 0,
  });
  final String id, title, artist;
  final int durationSeconds;
  String get thumbnail => 'https://i.ytimg.com/vi/$id/hqdefault.jpg';
  Uri get url => Uri.https('www.youtube.com', '/watch', {'v': id});
  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'artist': artist,
    'durationSeconds': durationSeconds,
  };
  factory OnlineTrack.fromJson(Map<String, dynamic> j) => OnlineTrack(
    id: j['id'] as String,
    title: j['title'] as String,
    artist: j['artist'] as String,
    durationSeconds: (j['durationSeconds'] as num?)?.toInt() ?? 0,
  );
}

int parseVideoDuration(String value) {
  var seconds = 0;
  for (final part in value.split(':')) {
    final n = int.tryParse(part);
    if (n == null || n < 0) return 0;
    seconds = seconds * 60 + n;
  }
  return seconds;
}

String? youtubeVideoId(String input) {
  final uri = Uri.tryParse(input.trim());
  if (uri == null || uri.scheme != 'https') return null;
  final host = uri.host.toLowerCase();
  String? id;
  if (host == 'youtu.be' && uri.pathSegments.isNotEmpty) {
    id = uri.pathSegments.first;
  }
  if (const [
    'youtube.com',
    'www.youtube.com',
    'm.youtube.com',
  ].contains(host)) {
    if (uri.path == '/watch') id = uri.queryParameters['v'];
    if (uri.pathSegments.length >= 2 &&
        ['shorts', 'embed', 'live'].contains(uri.pathSegments.first)) {
      id = uri.pathSegments[1];
    }
  }
  return id != null && RegExp(r'^[a-zA-Z0-9_-]{11}$').hasMatch(id) ? id : null;
}

bool youtubeReachedEnd({
  required String expectedId,
  required String actualId,
  required Duration duration,
  required Duration position,
}) =>
    expectedId == actualId &&
    duration > Duration.zero &&
    position.inMilliseconds >= duration.inMilliseconds - 1500;
