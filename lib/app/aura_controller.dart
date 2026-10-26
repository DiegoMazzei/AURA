import 'dart:async';
import 'dart:math';

import 'package:flutter/foundation.dart' show compute;

import 'package:flutter/material.dart';

import '../core/audio/audio_engine.dart';
import '../core/storage/library_store.dart';
import '../shared/models/music.dart';
import '../features/spotify_import/metadata_import.dart';
import '../features/youtube/online_track.dart';
import '../features/youtube/youtube_catalog.dart';

enum RepeatSetting { off, all, one }

class AuraController extends ChangeNotifier {
  AuraController({
    required this.audio,
    required this.store,
    DateTime Function()? now,
    MusicCatalog? catalog,
  }) : now = now ?? DateTime.now,
       catalog = catalog ?? YoutubeCatalog() {
    audio.addListener(_audioChanged);
    audio.onComplete = _completed;
  }
  final DateTime Function() now;
  final MusicCatalog catalog;
  final Map<String, OnlineTrack> onlineRecords = {};
  final Set<String> onlineFavorites = {};
  List<AuraPlaylist> onlinePlaylists = [];
  List<String> onlineQueue = [];
  String? onlineCurrentId;
  OnlineTrack? get onlineCurrent => onlineRecords[onlineCurrentId];
  final AudioEngine audio;
  final LibraryStore store;
  List<Track> tracks = List.of(demoTracks);
  List<AuraPlaylist> playlists = [];
  List<ImportedCollection> importedCollections = [];
  final Set<String> favorites = {};
  List<String> recent = [];
  List<String> queue = demoTracks.map((t) => t.id).toList();
  String currentId = demoTracks.first.id;
  ThemeMode themeMode = ThemeMode.system;
  RepeatSetting repeat = RepeatSetting.off;
  bool shuffle = false, ready = false, busy = false, importing = false;
  double volume = .8;
  String? error;
  String? _loadedId;
  bool _disposed = false;
  Future<void> _writes = Future.value();
  Timer? _positionSave;
  Track get current =>
      tracks.firstWhere((t) => t.id == currentId, orElse: () => tracks.first);
  Track? track(String id) {
    for (final t in tracks) {
      if (t.id == id) return t;
    }
    return null;
  }

  List<Track> get libraryTracks => tracks
      .where(
        (t) =>
            !t.isYoutube ||
            favorites.contains(t.id) ||
            recent.contains(t.id) ||
            playlists.any((p) => p.trackIds.contains(t.id)),
      )
      .toList();
  List<Track> get queueTracks => queue.map(track).whereType<Track>().toList();
  List<Track> tracksFor(AuraPlaylist p) =>
      p.trackIds.map(track).whereType<Track>().toList();
  Duration get duration =>
      _loadedId == currentId && audio.duration > Duration.zero
      ? audio.duration
      : Duration(seconds: current.durationSeconds);
  Duration get position =>
      _loadedId == currentId ? audio.position : _restoredPosition;
  Duration _restoredPosition = Duration.zero;

  Future<void> initialize() async {
    try {
      final data = await store.read();
      if (_disposed) return;
      if (data != null) {
        for (final j in data['onlineRecords'] as List? ?? []) {
          final t = OnlineTrack.fromJson(Map<String, dynamic>.from(j as Map));
          onlineRecords[t.id] = t;
        }
        onlineFavorites.addAll(
          List<String>.from(data['onlineFavorites'] as List? ?? [])
              .where(onlineRecords.containsKey),
        );
        onlinePlaylists = (data['onlinePlaylists'] as List? ?? [])
            .map(
              (j) => AuraPlaylist.fromJson(Map<String, dynamic>.from(j as Map)),
            )
            .toList();
        onlineQueue = List<String>.from(data['onlineQueue'] as List? ?? [])
            .where(onlineRecords.containsKey)
            .toList();
        onlineCurrentId = data['onlineCurrentId'] as String?;
        importedCollections = (data['importedCollections'] as List? ?? [])
            .map(
              (j) => ImportedCollection.fromJson(
                Map<String, dynamic>.from(j as Map),
              ),
            )
            .toList();
        final imported = (data['tracks'] as List? ?? [])
            .map((j) => Track.fromJson(Map<String, dynamic>.from(j as Map)))
            .toList();
        tracks = [
          ...demoTracks.map((t) {
            final lines = (data['demoLyrics'] as Map?)?[t.id] as List?;
            final base = lines == null
                ? t
                : t.withLyrics(
                    lines
                        .map(
                          (l) => LyricLine(
                            Duration(milliseconds: l['ms'] as int),
                            l['text'] as String,
                          ),
                        )
                        .toList(),
                  );
            final info = (data['demoMetadata'] as Map?)?[t.id] as Map?;
            return info == null
                ? base
                : base.copyWith(
                    title: info['title'] as String?,
                    artist: info['artist'] as String?,
                    album: info['album'] as String?,
                    metadataEdited: info['metadataEdited'] == true,
                  );
          }),
          ...imported,
        ];
        for (final id in onlineFavorites) {
          final t = onlineRecords[id];
          if (t != null) {
            final native = nativeTrackFor(t);
            favorites.add(native.id);
          }
        }
        favorites.addAll(
          List<String>.from(data['favorites'] as List? ?? [])
              .where((id) => track(id) != null),
        );
        playlists = (data['playlists'] as List? ?? [])
            .map(
              (j) => AuraPlaylist.fromJson(Map<String, dynamic>.from(j as Map)),
            )
            .toList();
        if (data['onlineLibraryMigrated'] != true) {
          for (final old in onlinePlaylists) {
            final ids = old.trackIds
                .map((id) => onlineRecords[id])
                .whereType<OnlineTrack>()
                .map((t) => nativeTrackFor(t).id)
                .toList();
            playlists.add(
              AuraPlaylist(
                id: 'ytlist:${old.id}',
                name: old.name,
                trackIds: ids,
              ),
            );
          }
        }
        recent = List<String>.from(data['recent'] as List? ?? [])
            .where((id) => track(id) != null)
            .toList();
        final restoredQueue = List<String>.from(data['queue'] as List? ?? [])
            .where((id) => track(id) != null)
            .toList();
        if (restoredQueue.isNotEmpty) queue = restoredQueue;
        final id = data['current'] as String?;
        if (id != null && track(id) != null) currentId = id;
        themeMode = ThemeMode.values.firstWhere(
          (v) => v.name == data['theme'],
          orElse: () => ThemeMode.system,
        );
        repeat = RepeatSetting.values.firstWhere(
          (v) => v.name == data['repeat'],
          orElse: () => RepeatSetting.off,
        );
        shuffle = data['shuffle'] == true;
        volume = ((data['volume'] as num?)?.toDouble() ?? .8).clamp(0, 1);
        _restoredPosition = Duration(
          milliseconds: (data['position'] as num?)?.toInt() ?? 0,
        );
        final previousVideo = onlineRecords[onlineCurrentId];
        if (previousVideo != null) {
          currentId = nativeTrackFor(previousVideo).id;
          queue = [currentId, ...queue.where((id) => id != currentId)];
          onlineCurrentId = null;
          _restoredPosition = Duration.zero;
        }
      }
    } catch (_) {
      error = 'La libreria salvata non è leggibile. I file originali sono conservati.';
    }
    if (_disposed) return;
    ready = true;
    _positionSave = Timer.periodic(const Duration(seconds: 5), (_) {
      if (audio.playing) unawaited(save());
    });
    notifyListeners();
  }

  Map<String, dynamic> snapshot() => {
    'version': 1,
    'onlineLibraryMigrated': true,
    'onlineRecords': onlineRecords.values.map((t) => t.toJson()).toList(),
    'onlineFavorites': onlineFavorites.toList(),
    'onlinePlaylists': onlinePlaylists.map((p) => p.toJson()).toList(),
    'onlineQueue': onlineQueue,
    'onlineCurrentId': onlineCurrentId,
    'importedCollections': importedCollections.map((c) => c.toJson()).toList(),
    'tracks': tracks.where((t) => !t.isAsset).map((t) => t.toJson()).toList(),
    'demoMetadata': {
      for (final t in tracks.where((v) => v.isAsset))
        t.id: {
          'title': t.title,
          'artist': t.artist,
          'album': t.album,
          'metadataEdited': t.metadataEdited,
        },
    },
    'demoLyrics': {
      for (final t in tracks.where((t) => t.isAsset))
        t.id: t.lyrics
            .map((l) => {'ms': l.at.inMilliseconds, 'text': l.text})
            .toList(),
    },
    'favorites': favorites.toList(),
    'playlists': playlists.map((p) => p.toJson()).toList(),
    'recent': recent,
    'queue': queue,
    'current': currentId,
    'position': position.inMilliseconds,
    'theme': themeMode.name,
    'repeat': repeat.name,
    'shuffle': shuffle,
    'volume': volume,
  };
  Future<void> save() {
    final data = snapshot();
    _writes = _writes.then((_) => store.write(data)).catchError((Object e) {
      if (!_disposed) {
        error = 'Salvataggio non riuscito. Verifica lo spazio sul dispositivo.';
        notifyListeners();
      }
    });
    return _writes;
  }

  bool _wasPlaying = false;
  String? _lastAudioError;
  void _audioChanged() {
    if (_disposed) return;
    if (audio.playing == _wasPlaying && audio.error == _lastAudioError) return;
    _wasPlaying = audio.playing;
    _lastAudioError = audio.error;
    if (audio.error != null) error = audio.error;
    notifyListeners();
  }

  void notifyStartupIssue() {
    notifyListeners();
  }

  void dismissError() {
    error = null;
    notifyListeners();
  }

  Future<void> playTrack(Track t, {List<Track>? contextTracks}) async {
    if (busy || !ready) return;
    busy = true;
    onlineCurrentId = null;
    error = null;
    if (contextTracks != null && contextTracks.isNotEmpty) {
      queue = contextTracks.map((t) => t.id).toSet().toList();
    }
    if (!queue.contains(t.id)) queue.add(t.id);
    final restore = t.id == currentId ? _restoredPosition : Duration.zero;
    currentId = t.id;
    notifyListeners();
    try {
      if (_loadedId != t.id) {
        await audio.load(t);
        if (_disposed) return;
        _loadedId = t.id;
        final details = audio.resolvedMetadata;
        if (details != null) {
          final i = tracks.indexWhere((v) => v.id == details.id);
          if (i >= 0) tracks[i] = details;
        }
        if (restore > Duration.zero && restore < audio.duration) {
          await audio.seek(restore);
        }
        _restoredPosition = Duration.zero;
      } else if (audio.position >= audio.duration &&
          audio.duration > Duration.zero) {
        await audio.seek(Duration.zero);
      }
      if (_disposed) return;
      await audio.setVolume(volume);
      audio.play();
      recent = [t.id, ...recent.where((id) => id != t.id)].take(30).toList();
      unawaited(save());
    } catch (_) {
      if (!_disposed) {
        error = current.isYoutube
            ? 'Questa sorgente YouTube non è disponibile. Riprova o scegli un altro risultato.'
            : 'Audio non disponibile. Controlla il file e riprova.';
      }
    } finally {
      if (!_disposed) {
        busy = false;
        notifyListeners();
      }
    }
  }

  Future<void> togglePlayback() async {
    if (busy) return;
    if (audio.playing) {
      await audio.pause();
      await save();
    } else {
      await playTrack(current);
    }
  }

  Future<void> seek(Duration value) async {
    if (_loadedId != currentId) return;
    final ms = value.inMilliseconds.clamp(0, duration.inMilliseconds);
    try {
      await audio.seek(Duration(milliseconds: ms));
      unawaited(save());
    } catch (_) {
      error = 'Impossibile spostare la riproduzione.';
      notifyListeners();
    }
  }

  Future<void> next({bool automatic = false}) async {
    if (busy || queue.isEmpty) return;
    final index = queue.indexOf(currentId);
    if (automatic && repeat == RepeatSetting.one) {
      await audio.seek(Duration.zero);
      audio.play();
      return;
    }
    if (automatic && index == queue.length - 1 && repeat == RepeatSetting.off) {
      await audio.pause();
      await audio.seek(Duration.zero);
      unawaited(save());
      return;
    }
    final candidates = queue.where((id) => id != currentId).toList();
    final nextId = shuffle && candidates.isNotEmpty
        ? candidates[Random().nextInt(candidates.length)]
        : queue[(index + 1) % queue.length];
    final t = track(nextId);
    if (t != null) await playTrack(t);
  }

  void _completed() {
    if (!busy) unawaited(next(automatic: true));
  }

  Future<void> previous() async {
    if (position.inSeconds > 3) {
      await seek(Duration.zero);
      return;
    }
    if (queue.isEmpty) return;
    final i = queue.indexOf(currentId);
    final t = track(queue[(i - 1 + queue.length) % queue.length]);
    if (t != null) await playTrack(t);
  }

  void toggleFavorite(String id) {
    favorites.contains(id) ? favorites.remove(id) : favorites.add(id);
    if (id.startsWith('yt:')) {
      final videoId = id.substring(3);
      if (favorites.contains(id)) {
        onlineFavorites.add(videoId);
      } else {
        onlineFavorites.remove(videoId);
      }
    }
    notifyListeners();
    unawaited(save());
  }

  void toggleShuffle() {
    shuffle = !shuffle;
    notifyListeners();
    unawaited(save());
  }

  void cycleRepeat() {
    repeat =
        RepeatSetting.values[(repeat.index + 1) % RepeatSetting.values.length];
    notifyListeners();
    unawaited(save());
  }

  void setTheme(ThemeMode mode) {
    themeMode = mode;
    notifyListeners();
    unawaited(save());
  }

  Future<void> setVolume(double value) async {
    volume = value;
    try {
      await audio.setVolume(value);
    } catch (_) {
      error = 'Impossibile regolare il volume.';
    }
    if (!_disposed) notifyListeners();
  }

  void reorderQueue(int from, int to) {
    final id = queue.removeAt(from);
    queue.insert(to, id);
    notifyListeners();
    unawaited(save());
  }

  void removeFromQueue(String id) {
    if (id == currentId) return;
    queue.remove(id);
    notifyListeners();
    unawaited(save());
  }

  void enqueue(Track t) {
    if (!queue.contains(t.id)) queue.add(t.id);
    notifyListeners();
    unawaited(save());
  }

  AuraPlaylist createPlaylist(String name) {
    final p = AuraPlaylist(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      name: name.trim(),
    );
    playlists.add(p);
    notifyListeners();
    unawaited(save());
    return p;
  }

  void renamePlaylist(AuraPlaylist p, String name) {
    p.name = name.trim();
    notifyListeners();
    unawaited(save());
  }

  void deletePlaylist(AuraPlaylist p) {
    playlists.remove(p);
    notifyListeners();
    unawaited(save());
  }

  void addToPlaylist(AuraPlaylist p, String id) {
    if (!p.trackIds.contains(id)) p.trackIds.add(id);
    notifyListeners();
    unawaited(save());
  }

  void removeFromPlaylist(AuraPlaylist p, String id) {
    p.trackIds.remove(id);
    notifyListeners();
    unawaited(save());
  }

  void reorderPlaylist(AuraPlaylist p, int from, int to) {
    final id = p.trackIds.removeAt(from);
    p.trackIds.insert(to, id);
    notifyListeners();
    unawaited(save());
  }

  Future<void> importAudio() async {
    if (importing) return;
    importing = true;
    notifyListeners();
    try {
      final imported = await store.importAudio();
      if (_disposed) return;
      tracks.addAll(imported);
      await save();
    } catch (_) {
      error = 'Importazione non riuscita. Scegli file audio disponibili sul dispositivo.';
    } finally {
      if (!_disposed) {
        importing = false;
        notifyListeners();
      }
    }
  }

  Future<void> selectOnline(
    OnlineTrack t, {
    List<OnlineTrack>? contextTracks,
  }) async {
    await audio.pause();
    for (final v in contextTracks ?? [t]) {
      onlineRecords[v.id] = v;
    }
    onlineRecords[t.id] = t;
    if (contextTracks != null) {
      onlineQueue = contextTracks.map((v) => v.id).toSet().toList();
    }
    if (!onlineQueue.contains(t.id)) onlineQueue.add(t.id);
    onlineCurrentId = t.id;
    notifyListeners();
    await save();
  }

  void refreshOnlineMetadata(OnlineTrack t) {
    onlineRecords[t.id] = t;
    notifyListeners();
    unawaited(save());
  }

  Track nativeTrackFor(OnlineTrack t) {
    final id = 'yt:${t.id}';
    final existing = track(id);
    if (existing != null) return existing;
    final value = Track(
      id: id,
      title: t.title,
      artist: t.artist,
      source: t.id,
      isYoutube: true,
      color: 0xffad96ff,
      durationSeconds: t.durationSeconds,
    );
    tracks.add(value);
    onlineRecords[t.id] = t;
    return value;
  }

  void favoriteOnline(OnlineTrack t) {
    final value = nativeTrackFor(t);
    toggleFavorite(value.id);
    if (favorites.contains(value.id)) {
      onlineFavorites.add(t.id);
    } else {
      onlineFavorites.remove(t.id);
    }
    unawaited(save());
  }

  void updateTrackMetadata(
    Track t, {
    required String title,
    required String artist,
    required String album,
  }) {
    final i = tracks.indexWhere((v) => v.id == t.id);
    if (i < 0) return;
    tracks[i] = t.copyWith(
      title: title.trim(),
      artist: artist.trim(),
      album: album.trim(),
      metadataEdited: true,
    );
    notifyListeners();
    unawaited(save());
  }

  AuraPlaylist createOnlinePlaylist(String name) => createPlaylist(name);
  void addOnlineTrack(AuraPlaylist p, OnlineTrack t) =>
      addToPlaylist(p, nativeTrackFor(t).id);
  void deleteOnlinePlaylist(AuraPlaylist p) {
    onlinePlaylists.remove(p);
    notifyListeners();
    unawaited(save());
  }

  Future<int?> importMusicMetadata() async {
    if (importing) return null;
    importing = true;
    error = null;
    notifyListeners();
    try {
      final source = await store.importMusicMetadata();
      if (source == null || _disposed) return null;
      final collections = await compute(parseMusicExport, source);
      if (_disposed) return null;
      final existing = importedCollections.map((c) => c.identity).toSet();
      final fresh = collections.where((c) => existing.add(c.identity)).toList();
      importedCollections.addAll(fresh);
      await save();
      return fresh.length;
    } catch (_) {
      if (!_disposed) error = 'File non riconosciuto. Usa un JSON di playlist o un CSV con colonne title e artist.';
      return null;
    } finally {
      if (!_disposed) {
        importing = false;
        notifyListeners();
      }
    }
  }

  Future<void> importLyrics(Track t) async {
    try {
      final text = await store.importLyrics();
      if (text == null || _disposed) return;
      final lines = parseLrc(text);
      if (lines.isEmpty) {
        error = 'Il file LRC non contiene righe con tempi validi.';
        notifyListeners();
        return;
      }
      final i = tracks.indexWhere((v) => v.id == t.id);
      tracks[i] = t.withLyrics(lines);
      notifyListeners();
      await save();
    } catch (_) {
      error = 'Impossibile leggere il file dei testi.';
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _disposed = true;
    catalog.dispose();
    _positionSave?.cancel();
    audio.removeListener(_audioChanged);
    audio.onComplete = null;
    audio.dispose();
    super.dispose();
  }
}
