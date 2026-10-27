import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:crypto/crypto.dart';

import '../../features/spotify_import/metadata_import.dart';
import '../../features/youtube/online_track.dart';
import '../../shared/models/music.dart';
import '../catalog/artist_directory.dart';

const catalogBackupLimit = 100 * 1024 * 1024;
final _audioPath = RegExp(r'^audio/[A-Za-z0-9][A-Za-z0-9._-]{0,140}\.(?:mp3|m4a|aac|wav|flac|ogg)$');

class CatalogBackup {
  CatalogBackup(this.catalog, this.audio);
  final Map<String, dynamic> catalog;
  final Map<String, Uint8List> audio;

  static Future<Uint8List> create(
    Map<String, dynamic> snapshot,
    Directory root,
  ) async {
    final catalog = <String, dynamic>{
      for (final key in [
        'version',
        'tracks',
        'favorites',
        'favoriteArtists',
        'playlists',
        'recent',
        'importedCollections',
        'displayName',
        'theme',
        'accentColor',
        'onlineRecords',
        'onlineFavorites',
        'onlinePlaylists',
        'onlineLibraryMigrated',
      ])
        if (snapshot.containsKey(key)) key: snapshot[key],
    };
    validateCatalog(catalog);
    final archive = Archive();
    final hashes = <String, String>{};
    var total = 0;
    final rootPath = await root.resolveSymbolicLinks();
    for (final raw in catalog['tracks'] as List? ?? []) {
      final track = Track.fromJson(Map<String, dynamic>.from(raw as Map));
      if (track.isYoutube || hashes.containsKey(track.source)) continue;
      final file = File('$rootPath/${track.source}');
      if (!await file.exists()) {
        throw const FormatException(
          'Un file audio locale non è disponibile. Reimportalo prima del backup.',
        );
      }
      final real = await file.resolveSymbolicLinks();
      if (!real.startsWith('$rootPath/')) {
        throw const FormatException('Percorso audio non valido.');
      }
      total += await file.length();
      if (total > catalogBackupLimit) {
        throw const FormatException('Il backup supera 100 MB di file locali.');
      }
      final bytes = await file.readAsBytes();
      hashes[track.source] = sha256.convert(bytes).toString();
      archive.addFile(ArchiveFile.bytes(track.source, bytes));
    }
    final manifest = utf8.encode(
      jsonEncode({
        'format': 'aura-catalog',
        'schema': 1,
        'catalog': catalog,
        'files': hashes,
      }),
    );
    if (manifest.length > 20 * 1024 * 1024 ||
        total + manifest.length > catalogBackupLimit) {
      throw const FormatException(
        'Il catalogo è troppo grande per questo formato di backup.',
      );
    }
    archive.addFile(ArchiveFile.bytes('catalog.json', manifest));
    final result = Uint8List.fromList(ZipEncoder().encode(archive));
    if (result.length > catalogBackupLimit) {
      throw const FormatException('Il backup supera 100 MB.');
    }
    return result;
  }

  static CatalogBackup decode(Uint8List bytes) {
    if (bytes.length > catalogBackupLimit) {
      throw const FormatException('Il backup supera 100 MB.');
    }
    try {
      final archive = ZipDecoder().decodeBytes(bytes);
      var total = 0;
      final entries = <String, ArchiveFile>{};
      for (final entry in archive) {
        if (!entry.isFile ||
            entry.isSymbolicLink ||
            (entry.name != 'catalog.json' &&
                !_audioPath.hasMatch(entry.name)) ||
            entries.containsKey(entry.name)) {
          throw const FormatException('Contenuto del backup non valido.');
        }
        total += entry.size;
        if (entry.size < 0 || total > catalogBackupLimit) {
          throw const FormatException(
            'Il backup supera 100 MB dopo l’estrazione.',
          );
        }
        entries[entry.name] = entry;
      }
      final manifest = entries.remove('catalog.json');
      if (manifest == null || manifest.size > 20 * 1024 * 1024) {
        throw const FormatException('Catalogo AURA mancante.');
      }
      final envelope = jsonDecode(utf8.decode(manifest.content)) as Map;
      if (envelope['format'] != 'aura-catalog' || envelope['schema'] != 1) {
        throw const FormatException(
          'Formato o versione del backup non supportati.',
        );
      }
      final catalog = Map<String, dynamic>.from(envelope['catalog'] as Map);
      validateCatalog(catalog);
      final hashes = Map<String, dynamic>.from(envelope['files'] as Map);
      if (hashes.length != entries.length) {
        throw const FormatException('File audio del backup incompleti.');
      }
      final audio = <String, Uint8List>{};
      for (final entry in entries.entries) {
        final content = entry.value.content;
        if (content.length != entry.value.size ||
            sha256.convert(content).toString() != hashes[entry.key]) {
          throw const FormatException(
            'Un file audio del backup è danneggiato.',
          );
        }
        audio[entry.key] = content;
      }
      for (final raw in catalog['tracks'] as List? ?? []) {
        final t = Track.fromJson(Map<String, dynamic>.from(raw as Map));
        if (!t.isYoutube && !audio.containsKey(t.source)) {
          throw const FormatException('Un file audio locale manca dal backup.');
        }
      }
      return CatalogBackup(catalog, audio);
    } on FormatException {
      rethrow;
    } catch (_) {
      throw const FormatException('Il file non è un backup AURA valido.');
    }
  }

  late final Map<String, String> audioPaths = {
    for (final entry in audio.entries)
      entry.key:
          'audio/restore-${sha256.convert(entry.value)}.${entry.key.split('.').last}',
  };
}

void validateCatalog(Map<String, dynamic> data) {
  if (data['version'] != 1) {
    throw const FormatException('Versione del catalogo non supportata.');
  }
  final ids = <String>{};
  for (final raw in data['tracks'] as List? ?? []) {
    if (ids.length >= 50000) {
      throw const FormatException('Troppe tracce nel catalogo.');
    }
    final t = Track.fromJson(Map<String, dynamic>.from(raw as Map));
    if (t.id.isEmpty ||
        !ids.add(t.id) ||
        (t.isYoutube
            ? (t.source.isNotEmpty &&
                  !RegExp(r'^[A-Za-z0-9_-]{11}$').hasMatch(t.source))
            : !_audioPath.hasMatch(t.source))) {
      throw const FormatException('Traccia o percorso audio non valido.');
    }
  }
  for (final raw in data['playlists'] as List? ?? []) {
    AuraPlaylist.fromJson(Map<String, dynamic>.from(raw as Map));
  }
  for (final raw in data['favoriteArtists'] as List? ?? []) {
    DirectoryArtist.fromJson(Map<String, dynamic>.from(raw as Map));
  }
  for (final raw in data['importedCollections'] as List? ?? []) {
    ImportedCollection.fromJson(Map<String, dynamic>.from(raw as Map));
  }
  for (final raw in data['onlineRecords'] as List? ?? []) {
    OnlineTrack.fromJson(Map<String, dynamic>.from(raw as Map));
  }
  for (final key in ['favorites', 'recent', 'onlineFavorites']) {
    List<String>.from(data[key] as List? ?? []);
  }
  if (data['accentColor'] != null && data['accentColor'] is! num) {
    throw const FormatException('Colore non valido.');
  }
  if (data['theme'] != null &&
      !['system', 'light', 'dark'].contains(data['theme'])) {
    throw const FormatException('Tema non valido.');
  }
  if (data['displayName'] != null && data['displayName'] is! String) {
    throw const FormatException('Profilo non valido.');
  }
}

/// Merge without replacing existing metadata or removing the receiving library.
Map<String, dynamic> mergeCatalog(
  Map<String, dynamic> current,
  CatalogBackup backup,
) {
  final incoming = backup.catalog;
  final result = Map<String, dynamic>.from(current);
  final tracks = {
    for (final raw in current['tracks'] as List? ?? [])
      (raw as Map)['id'] as String: Map<String, dynamic>.from(raw),
  };
  final idMap = <String, String>{};
  for (final raw in incoming['tracks'] as List? ?? []) {
    final t = Map<String, dynamic>.from(raw as Map);
    final id = t['id'] as String;
    if (t['isYoutube'] != true) t['source'] = backup.audioPaths[t['source']];
    var nextId = id;
    final existing = tracks[id];
    if (existing != null &&
        (existing['isYoutube'] != t['isYoutube'] ||
            (t['isYoutube'] == true
                ? existing['source'] != t['source']
                : existing['title'] != t['title'] ||
                      existing['artist'] != t['artist']))) {
      nextId = 'restore:${sha256.convert(utf8.encode(jsonEncode(t)))}';
    }
    idMap[id] = nextId;
    t['id'] = nextId;
    tracks.putIfAbsent(nextId, () => t);
  }
  result['tracks'] = tracks.values.toList();
  List<String> mapped(dynamic values) =>
      List<String>.from(values as List? ?? [])
          .map((id) => idMap[id])
          .whereType<String>()
          .toList();
  result['favorites'] = {
    ...List<String>.from(current['favorites'] as List? ?? []),
    ...mapped(incoming['favorites']),
  }.toList();
  result['recent'] = {
    ...List<String>.from(current['recent'] as List? ?? []),
    ...mapped(incoming['recent']),
  }.take(30).toList();
  final artists = {
    for (final raw in current['favoriteArtists'] as List? ?? [])
      (raw as Map)['id']: raw,
  };
  for (final raw in incoming['favoriteArtists'] as List? ?? []) {
    artists.putIfAbsent((raw as Map)['id'], () => raw);
  }
  result['favoriteArtists'] = artists.values.toList();
  final playlists = {
    for (final raw in current['playlists'] as List? ?? [])
      (raw as Map)['id'] as String: Map<String, dynamic>.from(raw),
  };
  for (final raw in incoming['playlists'] as List? ?? []) {
    final p = Map<String, dynamic>.from(raw as Map);
    var id = p['id'] as String;
    if (playlists[id] != null && playlists[id]!['name'] != p['name']) {
      id = 'restore:${sha256.convert(utf8.encode('$id:${p['name']}'))}';
    }
    final old = playlists[id];
    playlists[id] = {
      'id': id,
      'name': old?['name'] ?? p['name'],
      'trackIds': {
        ...List<String>.from(old?['trackIds'] as List? ?? []),
        ...mapped(p['trackIds']),
      }.toList(),
    };
  }
  result['playlists'] = playlists.values.toList();
  final collections = <String, Map<String, dynamic>>{};
  for (final raw in [
    ...(current['importedCollections'] as List? ?? []),
    ...(incoming['importedCollections'] as List? ?? []),
  ]) {
    final j = Map<String, dynamic>.from(raw as Map);
    collections.putIfAbsent(ImportedCollection.fromJson(j).identity, () => j);
  }
  result['importedCollections'] = collections.values.toList();
  final records = {
    for (final raw in current['onlineRecords'] as List? ?? [])
      (raw as Map)['id']: raw,
  };
  for (final raw in incoming['onlineRecords'] as List? ?? []) {
    records.putIfAbsent((raw as Map)['id'], () => raw);
  }
  result['onlineRecords'] = records.values.toList();
  result['onlineFavorites'] = {
    ...List<String>.from(current['onlineFavorites'] as List? ?? []),
    ...List<String>.from(incoming['onlineFavorites'] as List? ?? []),
  }.toList();
  if ((current['tracks'] as List? ?? []).isEmpty &&
      (current['favoriteArtists'] as List? ?? []).isEmpty &&
      (current['playlists'] as List? ?? []).isEmpty) {
    for (final key in ['theme', 'accentColor']) {
      if (incoming.containsKey(key)) result[key] = incoming[key];
    }
    if ((current['displayName'] as String? ?? '').isEmpty) {
      result['displayName'] = incoming['displayName'] ?? '';
    }
  }
  return result;
}
