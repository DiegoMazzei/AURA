import 'dart:io';

import 'package:youtube_explode_dart/youtube_explode_dart.dart';

/// Online regression check: tests both an initial range and a later seek range.
/// A successful 1 KB probe alone previously hid the adaptive-source 403.
Future<void> main() async {
  final yt = YoutubeExplode();
  final client = HttpClient();
  try {
    final manifest = await yt.videos.streams
        .getManifest('M7lc1UVf-VE')
        .timeout(const Duration(seconds: 35));
    final source = manifest.muxed
        .where((s) => s.container == StreamContainer.mp4)
        .first;
    for (final range in ['bytes=0-1', 'bytes=1048576-2097151']) {
      final request = await client.getUrl(source.url);
      request.headers.set('Range', range);
      final response = await request.close().timeout(
        const Duration(seconds: 15),
      );
      if (response.statusCode != 206) {
        throw StateError('Playback range failed (${response.statusCode})');
      }
      await response.drain<void>();
      stdout.writeln('AURA_PLAYBACK_RANGE_PASSED: $range');
    }
  } finally {
    client.close(force: true);
    yt.close();
  }
}
