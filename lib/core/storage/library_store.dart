import 'dart:convert';
import 'dart:io';
import 'dart:isolate';

import 'package:audio_metadata_reader/audio_metadata_reader.dart';

import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';

import '../../shared/models/music.dart';

abstract class LibraryStore {
  Future<Map<String, dynamic>?> read();
  Future<void> write(Map<String, dynamic> data);
  Future<List<Track>> importAudio();
  Future<String?> importLyrics();
  Future<String?> importMusicMetadata();
}

class DeviceLibraryStore implements LibraryStore {
  DeviceLibraryStore({this.directory});
  final Future<Directory> Function()? directory;
  Future<Directory> _root() async {
    if (directory != null) return directory!();
    final docs = await getApplicationDocumentsDirectory();
    return Directory('${docs.path}/aura').create(recursive: true);
  }

  Future<Directory> libraryDirectory() => _root();

  @override
  Future<Map<String, dynamic>?> read() async {
    final file = File('${(await _root()).path}/library.json');
    if (!await file.exists()) return null;
    try {
      final data =
          jsonDecode(await file.readAsString()) as Map<String, dynamic>;
      if (data['version'] != 1) {
        throw const FormatException('Unsupported library version');
      }
      return data;
    } catch (_) {
      await file.copy(
        '${file.path}.backup-${DateTime.now().microsecondsSinceEpoch}',
      );
      rethrow;
    }
  }

  @override
  Future<void> write(Map<String, dynamic> data) async {
    final root = await _root();
    final temp = File('${root.path}/library.pending.json');
    await temp.writeAsString(jsonEncode(data), flush: true);
    await temp.rename('${root.path}/library.json');
  }

  @override
  Future<List<Track>> importAudio() async {
    final files = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['mp3', 'm4a', 'aac', 'wav', 'flac', 'ogg'],
    );
    final result = <Track>[];
    final root = await _root();
    final audio = await Directory('${root.path}/audio').create(recursive: true);
    try {
      for (var i = 0; i < files.length; i++) {
        final picked = files[i];
        final ext = picked.name.split('.').last.toLowerCase();
        final id = '${DateTime.now().microsecondsSinceEpoch}-$i';
        final target = File('${audio.path}/$id.$ext');
        final sink = target.openWrite();
        try {
          await sink.addStream(picked.readAsByteStream());
        } finally {
          await sink.close();
        }
        final tags = await readLocalTrackTags(target.path);
        result.add(
          Track(
            id: id,
            title: (tags['title'] as String?)?.isNotEmpty == true
                ? tags['title'] as String
                : picked.name.replaceFirst(RegExp(r'\.[^.]+$'), ''),
            artist: (tags['artist'] as String?)?.isNotEmpty == true
                ? tags['artist'] as String
                : 'Artista sconosciuto',
            album: tags['album'] as String? ?? '',
            durationSeconds: tags['duration'] as int? ?? 0,
            source: 'audio/$id.$ext',
            color: [0xff78adff, 0xffe9a0cd, 0xffbca3ff][i % 3],
          ),
        );
      }
    } catch (_) {
      for (final track in result) {
        final file = File('${root.path}/${track.source}');
        if (await file.exists()) await file.delete();
      }
      rethrow;
    }
    return result;
  }

  @override
  Future<String?> importMusicMetadata() async {
    final picked = await FilePicker.pickFile(
      type: FileType.custom,
      allowedExtensions: ['json', 'csv'],
    );
    if (picked == null) return null;
    final size = await picked.length();
    if (size != null && size > 20 * 1024 * 1024) {
      throw const FormatException('Metadata file too large');
    }
    return utf8.decode(await picked.readAsBytes());
  }

  static Future<String> resolve(String relativePath) async {
    final docs = await getApplicationDocumentsDirectory();
    return '${docs.path}/aura/$relativePath';
  }

  @override
  Future<String?> importLyrics() async {
    final picked = await FilePicker.pickFile(
      type: FileType.custom,
      allowedExtensions: ['lrc'],
    );
    return picked == null ? null : utf8.decode(await picked.readAsBytes());
  }
}

Future<Map<String, Object?>> readLocalTrackTags(String path) => Isolate.run(() {
  try {
    final tags = readMetadata(File(path), getImage: false);
    return <String, Object?>{
      'title': tags.title?.trim(),
      'artist': tags.artist?.trim(),
      'album': tags.album?.trim(),
      'duration': tags.duration?.inSeconds,
    };
  } catch (_) {
    return <String, Object?>{};
  }
});
