import 'package:youtube_explode_dart/youtube_explode_dart.dart';

class ResolvedYoutubeAudio {
  const ResolvedYoutubeAudio({
    required this.uri,
    this.title,
    this.artist,
    this.album,
    this.duration,
  });
  final Uri uri;
  final String? title, artist, album;
  final Duration? duration;
}

/// Experimental source adapter. No credentials, cookies, DRM or challenge solver.
/// Media URLs are transient and are never written into the user's library.
class YoutubeAudioResolver {
  Future<ResolvedYoutubeAudio> resolve(String id) async {
    final yt = YoutubeExplode();
    try {
      final manifest = await yt.videos.streams
          .getManifest(id)
          .timeout(const Duration(seconds: 30));
      // Progressive MP4 remains compatible with native open-ended range
      // requests. Adaptive SDK-less audio can advertise URLs that then return
      // 403 on later ranges even after the initial bytes were accepted.
      final progressive =
          manifest.muxed
              .where((s) => s.container == StreamContainer.mp4)
              .toList()
            ..sort(
              (a, b) =>
                  a.bitrate.bitsPerSecond.compareTo(b.bitrate.bitsPerSecond),
            );
      final audio =
          manifest.audioOnly
              .where((s) => s.container == StreamContainer.mp4)
              .toList()
            ..sort(
              (a, b) =>
                  b.bitrate.bitsPerSecond.compareTo(a.bitrate.bitsPerSecond),
            );
      final source = progressive.isNotEmpty
          ? progressive.first
          : audio.isNotEmpty
          ? audio.first
          : null;
      if (source == null) throw StateError('No compatible source');
      String? title, artist, album;
      Duration? duration;
      try {
        final video = await yt.videos
            .get(id)
            .timeout(const Duration(seconds: 8));
        duration = video.duration;
        if (video.musicData.isNotEmpty) {
          final data = video.musicData.first;
          title = data.song;
          artist = data.artist;
          album = data.album;
        }
      } catch (_) {
        /* Missing music tags must not prevent a playable source. */
      }
      return ResolvedYoutubeAudio(
        uri: source.url,
        title: title,
        artist: artist,
        album: album,
        duration: duration,
      );
    } finally {
      yt.close();
    }
  }
}
