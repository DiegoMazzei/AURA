import 'dart:async';

import 'package:aura/features/youtube/online_track.dart';
import 'package:aura/features/youtube/youtube_catalog.dart';

import 'package:aura/core/audio/audio_engine.dart';
import 'package:aura/core/storage/library_store.dart';
import 'package:aura/shared/models/music.dart';

class FakeAudioEngine extends AudioEngine {
  @override
  Duration position = Duration.zero;
  @override
  Duration duration = const Duration(seconds: 40);
  @override
  bool playing = false;
  @override
  String? error;
  bool failLoad = false;
  String? loadedId;
  int loadCount = 0;
  @override
  Future<void> load(Track track) async {
    loadCount++;
    error = null;
    if (failLoad) throw StateError('fixture load failure');
    loadedId = track.id;
    position = Duration.zero;
    playing = false;
    notifyListeners();
  }

  @override
  void play() {
    playing = true;
    notifyListeners();
  }

  @override
  Future<void> pause() async {
    playing = false;
    notifyListeners();
  }

  @override
  Future<void> seek(Duration value) async {
    position = value;
    notifyListeners();
  }

  @override
  Future<void> setVolume(double value) async {}
  void advance(Duration value) {
    position = value;
    notifyListeners();
  }

  Future<void> complete() async {
    playing = false;
    position = duration;
    onComplete?.call();
    await Future<void>.delayed(Duration.zero);
  }
}

class MemoryLibraryStore implements LibraryStore {
  Map<String, dynamic>? data;
  bool failRead = false, failWrite = false, failImport = false;
  List<Track> imported = [];
  String? lrc;
  String? metadata;
  @override
  Future<Map<String, dynamic>?> read() async {
    if (failRead) throw StateError('fixture read failure');
    return data;
  }

  @override
  Future<void> write(Map<String, dynamic> value) async {
    if (failWrite) throw StateError('fixture write failure');
    data = value;
  }

  @override
  Future<List<Track>> importAudio() async {
    if (failImport) throw StateError('fixture import failure');
    return imported;
  }

  @override
  Future<String?> importLyrics() async => lrc;
  @override
  Future<String?> importMusicMetadata() async => metadata;
}

class FakeMusicCatalog implements MusicCatalog {
  List<OnlineTrack> results = [];
  final Map<String, Completer<List<OnlineTrack>>> pending = {};
  final List<String> requests = [];
  bool fail = false;
  @override
  Future<List<OnlineTrack>> search(String query) async {
    requests.add(query);
    if (fail) throw StateError('fixture catalog offline');
    return pending[query]?.future ?? results;
  }

  @override
  void dispose() {}
}
