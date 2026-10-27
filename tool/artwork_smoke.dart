import 'dart:io';

import 'package:aura/core/artwork/music_artwork.dart';
import 'package:aura/core/catalog/music_json_client.dart';

Future<void> main() async {
  final images = MusicArtwork(PublicMusicJsonClient());
  final photo = await images.artist('Gemitaiz');
  final cover = await images.album('Gemitaiz', 'ELSEWHERE');
  for (final url in [photo, cover]) {
    if (url == null) throw StateError('Artwork missing');
    final client = HttpClient();
    try {
      final response = await (await client.headUrl(Uri.parse(url))).close();
      if (response.statusCode != 200 ||
          !(response.headers.contentType?.mimeType.startsWith('image/') ??
              false)) {
        throw StateError('Artwork unavailable');
      }
      stdout.writeln(
        'ARTWORK_OK: ${Uri.parse(url).host} ${response.headers.contentType?.mimeType}',
      );
      await response.drain<void>();
    } finally {
      client.close(force: true);
    }
  }
}
