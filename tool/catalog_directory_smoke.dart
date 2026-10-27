import 'dart:io';

import 'package:aura/core/catalog/artist_directory.dart';
import 'package:aura/core/catalog/music_json_client.dart';

Future<void> main() async {
  final directory = AppleArtistDirectory(PublicMusicJsonClient());
  final results = await directory.search('Gemitaiz');
  final artist = results.artists.firstWhere(
    (a) => a.name.toLowerCase() == 'gemitaiz',
  );
  final albums = await directory.albums(artist);
  if (albums.isEmpty || results.songs.isEmpty) {
    throw StateError('Missing catalog');
  }
  final album = albums.firstWhere((a) => a.trackCount > 5);
  final songs = await directory.songs(album);
  if (songs.isEmpty) throw StateError('Missing tracklist');
  stdout.writeln(
    'DIRECTORY_SMOKE: ${artist.name}; ${albums.length} releases; ${results.songs.length} search songs; ${album.title}: ${songs.length} tracks',
  );
}
