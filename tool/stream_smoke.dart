import 'dart:io';

import 'package:youtube_explode_dart/youtube_explode_dart.dart';

Future<void> main() async {
  final yt = YoutubeExplode();
  try {
    final manifest = await yt.videos.streams
        .getManifest('M7lc1UVf-VE')
        .timeout(const Duration(seconds: 35));
    final audio = manifest.audioOnly
        .where((s) => s.container == StreamContainer.mp4)
        .toList();
    if (audio.isEmpty) throw StateError('No compatible audio source');
    stdout.writeln(
      'AURA_STREAM_DISCOVERY_PASSED: ${audio.length} compatible audio sources',
    );
    final client = HttpClient();
    try {
      for (final source in audio) {
        final request = await client.getUrl(source.url);
        request.headers.set('Range', 'bytes=0-1023');
        final response = await request.close().timeout(
          const Duration(seconds: 15),
        );
        stdout.writeln(
          'AURA_STREAM_HTTP: status=${response.statusCode}, contentType=${response.headers.contentType}, codec=${source.codec.mimeType}',
        );
      }
    } finally {
      client.close(force: true);
    }
  } finally {
    yt.close();
  }
}
