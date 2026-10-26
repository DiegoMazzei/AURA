import 'dart:io';

import 'package:aura/features/youtube/youtube_catalog.dart';

Future<void> main() async {
  final catalog = YoutubeCatalog();
  try {
    final results = await catalog.search(
      'YouTube Developers IFrame Player API',
    );
    if (results.isEmpty) throw StateError('No live search results');
    stdout.writeln(
      'AURA_LIVE_SEARCH_PASSED: ${results.length} results; first id=${results.first.id}; title=${results.first.title}',
    );
  } finally {
    catalog.dispose();
  }
}
