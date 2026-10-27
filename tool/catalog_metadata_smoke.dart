import 'dart:io';

import 'package:aura/core/catalog/music_json_client.dart';
import 'package:aura/core/catalog/musicbrainz_catalog.dart';
import 'package:aura/core/lyrics/lyrics_provider.dart';
import 'package:aura/shared/models/music.dart';

Future<void> main() async {
  final client = PublicMusicJsonClient();
  const song = Track(
    id: 'smoke',
    title: 'Get Lucky',
    artist: 'Daft Punk',
    album: 'Random Access Memories',
    source: 'none',
    durationSeconds: 369,
  );
  final matches = await ResilientMetadataCatalog(client).search(song);
  stdout.writeln(
    'AURA_METADATA_SMOKE: ${matches.length} recordings, ${matches.where((m) => m.identity.releaseGroupId.isNotEmpty).length} with release groups',
  );
  if (matches.isEmpty) throw StateError('No catalog results');
  stdout.writeln('AURA_METADATA_PROVIDER: ${matches.first.identity.provider}');
  final lyrics = await LrclibLyricsProvider(client).search(song);
  stdout.writeln(
    'AURA_LYRICS_SMOKE: ${lyrics.length} candidates, ${lyrics.where((l) => l.synchronized).length} synchronized',
  );
  if (lyrics.isEmpty) throw StateError('No lyrics results');
}
