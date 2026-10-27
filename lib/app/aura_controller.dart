import 'dart:async';
import 'dart:math';

import 'package:flutter/foundation.dart' show compute;

import 'package:flutter/material.dart';

import '../core/audio/audio_engine.dart';
import '../core/artwork/music_artwork.dart';
import '../core/catalog/catalog_identity.dart';
import '../core/catalog/recording_search.dart';
import '../core/catalog/artist_directory.dart';
import '../core/catalog/artist_recommendations.dart';
import '../core/catalog/musicbrainz_catalog.dart';
import '../core/lyrics/lyrics_provider.dart';
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
    this.metadataCatalog,
    this.artistDirectory,
    this.artistRecommendations,
    this.artwork,
    this.lyricsProvider,
    this.includeDemoTracks = false,
  }) : now = now ?? DateTime.now,
       catalog = catalog ?? YoutubeCatalog() {
    if (includeDemoTracks) {
      tracks = List.of(demoTracks);
      queue = demoTracks.map((t) => t.id).toList();
      currentId = demoTracks.first.id;
    }
    audio.addListener(_audioChanged);
    audio.onComplete = _completed;
  }
  final bool includeDemoTracks;
  final DateTime Function() now;
  final MusicCatalog catalog;
  final MetadataCatalog? metadataCatalog;
  final ArtistDirectory? artistDirectory;
  final ArtistRecommendations? artistRecommendations;
  final ArtworkRepository? artwork;
  final Map<int, DirectoryArtist> favoriteArtists = {};
  final LyricsProvider? lyricsProvider;
  bool updatingCatalog = false;
  int catalogDone = 0, catalogTotal = 0;
  String? catalogMessage;
  final Map<String, DateTime> _catalogAttempts = {};
  final Map<String, OnlineTrack> onlineRecords = {};
  final Set<String> onlineFavorites = {};
  List<AuraPlaylist> onlinePlaylists = [];
  List<String> onlineQueue = [];
  String? onlineCurrentId;
  OnlineTrack? get onlineCurrent => onlineRecords[onlineCurrentId];
  final AudioEngine audio;
  final LibraryStore store;
  List<Track> tracks = [];
  List<AuraPlaylist> playlists = [];
  List<ImportedCollection> importedCollections = [];
  final Set<String> favorites = {};
  List<String> recent = [];
  List<String> queue = [];
  String currentId = '';
  String displayName = '';
  String spotifyClientId = '';
  bool equalizerEnabled = false;
  List<double> equalizerGains = List.filled(5, 0);
  Future<void> setEqualizer({
    bool? enabled,
    int? band,
    double? gain,
    List<double>? preset,
  }) async {
    final next = preset != null
        ? List<double>.of(preset)
        : List<double>.of(equalizerGains);
    if (band != null && gain != null) next[band] = gain.clamp(-12, 12);
    final active = enabled ?? equalizerEnabled;
    try {
      await audio.configureEqualizer(active, next);
      equalizerEnabled = active;
      equalizerGains = next;
      notifyListeners();
      unawaited(save());
    } catch (_) {
      error = 'Impossibile applicare il filtro audio.';
      notifyListeners();
    }
  }

  void setDisplayName(String value) {
    displayName = value
        .trim()
        .replaceAll(RegExp(r'\s+'), ' ')
        .characters
        .take(40)
        .toString();
    notifyListeners();
    unawaited(save());
  }

  void setSpotifyClientId(String value) {
    spotifyClientId = value.trim();
    notifyListeners();
    unawaited(save());
  }

  ThemeMode themeMode = ThemeMode.system;
  int accentColor = 0xff9750e8;
  void setAccentColor(int value) {
    accentColor = 0xff000000 | (value & 0xffffff);
    notifyListeners();
    unawaited(save());
  }

  RepeatSetting repeat = RepeatSetting.off;
  bool shuffle = false, ready = false, busy = false, importing = false;
  double volume = .8;
  String? error;
  String? _loadedId;
  bool _disposed = false;
  Future<void> _writes = Future.value();
  Timer? _positionSave;
  Track get current => tracks.firstWhere(
    (t) => t.id == currentId,
    orElse: () => tracks.isEmpty
        ? const Track(id: '', title: '', artist: '', source: '')
        : tracks.first,
  );
  bool get hasCurrent => current.id.isNotEmpty;
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
        displayName = data['displayName'] as String? ?? '';
        spotifyClientId = data['spotifyClientId'] as String? ?? '';
        equalizerEnabled = data['equalizerEnabled'] == true;
        final gains = (data['equalizerGains'] as List? ?? [])
            .whereType<num>()
            .map((v) => v.toDouble().clamp(-12.0, 12.0))
            .toList();
        if (gains.length == 5) equalizerGains = gains;
        for (final raw in data['favoriteArtists'] as List? ?? []) {
          final artist = DirectoryArtist.fromJson(
            Map<String, dynamic>.from(raw as Map),
          );
          favoriteArtists[artist.id] = artist;
        }
        if (data['artworkCache'] is Map) {
          artwork?.restoreCache(
            Map<String, dynamic>.from(data['artworkCache'] as Map),
          );
        }
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
          ...(includeDemoTracks ? demoTracks : <Track>[]).map((t) {
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
                    plainLyrics: info['plainLyrics'] as String?,
                    lyricsSource: info['lyricsSource'] as String?,
                    lyricsSourceUrl: info['lyricsSourceUrl'] as String?,
                  );
          }),
          ...imported.where(
            (t) =>
                includeDemoTracks ||
                (!t.isAsset && !demoTracks.any((demo) => demo.id == t.id)),
          ),
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
        accentColor =
            0xff000000 |
            (((data['accentColor'] as num?)?.toInt() ?? 0xff9750e8) & 0xffffff);
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
    if (track(currentId) == null && tracks.isNotEmpty) {
      currentId = tracks.first.id;
    }
    try {
      await audio.configureEqualizer(equalizerEnabled, equalizerGains);
    } catch (_) {
      equalizerEnabled = false;
    }
    ready = true;
    _positionSave = Timer.periodic(const Duration(seconds: 5), (_) {
      if (audio.playing) unawaited(save());
    });
    notifyListeners();
  }

  Map<String, dynamic> snapshot() => {
    'version': 1,
    'displayName': displayName,
    'spotifyClientId': spotifyClientId,
    'equalizerEnabled': equalizerEnabled,
    'equalizerGains': equalizerGains,
    'onlineLibraryMigrated': true,
    'onlineRecords': onlineRecords.values.map((t) => t.toJson()).toList(),
    'onlineFavorites': onlineFavorites.toList(),
    'onlinePlaylists': onlinePlaylists.map((p) => p.toJson()).toList(),
    'onlineQueue': onlineQueue,
    'onlineCurrentId': onlineCurrentId,
    'importedCollections': importedCollections.map((c) => c.toJson()).toList(),
    'tracks': tracks.where((t) => !t.isAsset).map((t) => t.toJson()).toList(),
    'demoMetadata': {
      for (final t in tracks.where((v) => v.isAsset)) t.id: t.toJson(),
    },
    'demoLyrics': {
      for (final t in tracks.where((t) => t.isAsset))
        t.id: t.lyrics
            .map((l) => {'ms': l.at.inMilliseconds, 'text': l.text})
            .toList(),
    },
    'favorites': favorites.toList(),
    'favoriteArtists': favoriteArtists.values.map((a) => a.toJson()).toList(),
    'artworkCache': artwork?.exportCache() ?? {},
    'playlists': playlists.map((p) => p.toJson()).toList(),
    'recent': recent,
    'queue': queue,
    'current': currentId,
    'position': position.inMilliseconds,
    'theme': themeMode.name,
    'accentColor': accentColor,
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

  Track _albumTrack(DirectorySong song) {
    final id = 'catalog:${song.identity.recordingId}';
    final existing = track(id);
    if (existing != null) return existing;
    final value = Track(
      id: id,
      title: song.title,
      artist: song.artist,
      album: song.album,
      source: '',
      isYoutube: true,
      durationSeconds: song.seconds,
      catalogIdentity: song.identity,
    );
    tracks.add(value);
    return value;
  }

  Future<void> playAlbumSong(
    DirectorySong song,
    List<DirectorySong> songs, {
    OnlineTrack? selected,
  }) async {
    if (busy || !ready) return;
    final ordered = List<DirectorySong>.of(songs)
      ..sort((a, b) {
        final disc = a.disc.compareTo(b.disc);
        return disc != 0 ? disc : a.number.compareTo(b.number);
      });
    final albumTracks = ordered.map(_albumTrack).toList();
    var target = _albumTrack(song);
    if (selected != null) {
      if (target.source != selected.id) _loadedId = null;
      target = target.copyWith(source: selected.id);
      tracks[tracks.indexWhere((t) => t.id == target.id)] = target;
      onlineRecords[selected.id] = selected;
    }
    // An explicit album start follows its numbered tracklist. Shuffle can be
    // enabled again by the user after starting playback.
    shuffle = false;
    await playTrack(target, contextTracks: albumTracks);
  }

  Future<void> _loadRecording(Track seed) async {
    if (!seed.id.startsWith('catalog:')) {
      await audio.load(seed);
      return;
    }
    Object? failure;
    if (seed.source.isNotEmpty) {
      try {
        await audio.load(seed);
        return;
      } catch (e) {
        failure = e;
      }
    }
    await audio.pause();
    final candidates = await findRecordings(catalog, seed);
    for (final candidate
        in candidates
            .where((t) => t.id != seed.source && matchesRecording(seed, t))
            .take(3)) {
      if (_disposed) return;
      final resolved = seed.copyWith(source: candidate.id);
      try {
        await audio.load(resolved);
        if (_disposed) return;
        tracks[tracks.indexWhere((t) => t.id == seed.id)] = resolved;
        onlineRecords[candidate.id] = candidate;
        return;
      } catch (e) {
        failure = e;
      }
    }
    throw failure ?? StateError('Nessuna registrazione compatibile');
  }

  Future<void> playTrack(Track t, {List<Track>? contextTracks}) async {
    if (busy || !ready || t.id.isEmpty) return;
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
      if (audio.error != null) _loadedId = null;
      if (_loadedId != t.id) {
        _loadedId = null;
        await _loadRecording(t);
        error = null;
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
      unawaited(enrichTrackMetadata(track(t.id) ?? t));
      unawaited(fetchLyrics(track(t.id) ?? t));
      unawaited(save());
    } catch (_) {
      if (!_disposed) {
        error = current.id.startsWith('catalog:')
            ? 'Registrazione non disponibile per “${current.title}”. Riprova tra poco. La scaletta è conservata.'
            : current.isYoutube
            ? 'Questo brano non è disponibile. Riprova o scegli un altro risultato.'
            : 'Audio non disponibile. Controlla il file e riprova.';
        unawaited(save());
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

  void toggleArtistFavorite(DirectoryArtist artist) {
    favoriteArtists.containsKey(artist.id)
        ? favoriteArtists.remove(artist.id)
        : favoriteArtists[artist.id] = artist;
    notifyListeners();
    unawaited(save());
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
      clearCatalog: true,
    );
    if (currentId == t.id) audio.updateMetadata(tracks[i]);
    notifyListeners();
    unawaited(save());
  }

  Future<bool> enrichTrackMetadata(Track seed, {bool force = false}) async {
    if (metadataCatalog == null || seed.isAsset || seed.metadataEdited) {
      return false;
    }
    if (!force &&
        (seed.catalogIdentity != null ||
            (_catalogAttempts[seed.id] != null &&
                now().difference(_catalogAttempts[seed.id]!).inHours < 24))) {
      return false;
    }
    _catalogAttempts[seed.id] = now();
    try {
      final candidates = await metadataCatalog!.search(seed);
      final confident = candidates
          .where((m) => isConfidentCatalogMatch(seed, m))
          .toList();
      if (confident.isEmpty) return false;
      // Distinct equally confident recordings require explicit selection.
      final first = confident.first;
      if (confident.any(
        (m) =>
            m.score == first.score &&
            m.identity.recordingId != first.identity.recordingId,
      )) {
        return false;
      }
      final current = track(seed.id);
      if (_disposed ||
          current == null ||
          current.metadataEdited ||
          current.title != seed.title ||
          current.artist != seed.artist) {
        return false;
      }
      applyCatalogIdentity(current, first.identity);
      return true;
    } catch (_) {
      return false;
    }
  }

  void applyCatalogIdentity(Track seed, CatalogIdentity identity) {
    final i = tracks.indexWhere((t) => t.id == seed.id);
    if (i < 0) return;
    final t = tracks[i];
    tracks[i] = t.copyWith(
      title: identity.title,
      artist: identity.artists.map((a) => a.name).join(', '),
      album: identity.album,
      catalogIdentity: identity,
      metadataEdited: false,
    );
    if (currentId == t.id) audio.updateMetadata(tracks[i]);
    notifyListeners();
    unawaited(save());
  }

  Future<void> enrichLibraryMetadata() async {
    if (updatingCatalog || metadataCatalog == null) return;
    updatingCatalog = true;
    catalogDone = 0;
    final pending = libraryTracks
        .where(
          (t) => !t.isAsset && !t.metadataEdited && t.catalogIdentity == null,
        )
        .toList();
    catalogTotal = pending.length;
    catalogMessage = null;
    notifyListeners();
    var matched = 0;
    for (final t in pending) {
      if (_disposed) return;
      if (await enrichTrackMetadata(t, force: true)) matched++;
      catalogDone++;
      notifyListeners();
    }
    if (_disposed) return;
    updatingCatalog = false;
    catalogMessage = matched > 0 ? '$matched brani aggiornati' : 'Nessuna associazione certa. Puoi scegliere i dati dalle opzioni del brano.';
    notifyListeners();
  }

  final Set<String> _lyricsLoading = {};
  Future<void> fetchLyrics(Track seed) async {
    if (lyricsProvider == null ||
        seed.lyrics.isNotEmpty ||
        seed.plainLyrics.isNotEmpty ||
        !_lyricsLoading.add(seed.id)) {
      return;
    }
    try {
      final found = await lyricsProvider!.search(seed);
      final compatible = found
          .where((r) => lyricsMatch(seed, r, requireTiming: false))
          .toList();
      final latest = track(seed.id);
      if (!_disposed &&
          latest != null &&
          latest.lyrics.isEmpty &&
          latest.plainLyrics.isEmpty &&
          compatible.isNotEmpty) {
        final r = compatible.first;
        attachLyrics(
          latest,
          lines: lyricsMatch(seed, r) ? parseLrc(r.synced) : [],
          plain: r.plain.isNotEmpty
              ? r.plain
              : parseLrc(r.synced).map((l) => l.text).join("\n"),
          source: 'LRCLIB',
          sourceUrl: r.sourceUrl,
        );
      }
    } catch (_) {
      /* Playback does not depend on lyric availability. */
    } finally {
      _lyricsLoading.remove(seed.id);
    }
  }

  void attachLyrics(
    Track seed, {
    required List<LyricLine> lines,
    String plain = '',
    String source = '',
    String sourceUrl = '',
  }) {
    final i = tracks.indexWhere((t) => t.id == seed.id);
    if (i < 0) return;
    tracks[i] = tracks[i].copyWith(
      lyrics: lines,
      plainLyrics: plain,
      lyricsSource: source,
      lyricsSourceUrl: sourceUrl,
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

  Future<void> importSpotifyCollections(
    List<ImportedCollection> collections,
  ) async {
    for (final collection in collections) {
      final ids = <String>[];
      for (final song in collection.songs) {
        final sourceId = song.uri.startsWith('spotify:track:')
            ? song.uri.substring(14)
            : Uri.encodeComponent(song.identity);
        final id = 'catalog:spotify:$sourceId';
        if (track(id) == null) {
          tracks.add(
            Track(
              id: id,
              title: song.title,
              artist: song.artist,
              album: song.album,
              source: '',
              isYoutube: true,
              durationSeconds: song.durationSeconds,
              catalogIdentity: CatalogIdentity(
                provider: 'Spotify',
                recordingId: 'spotify:$sourceId',
                title: song.title,
                album: song.album,
                artists: song.artist
                    .split(', ')
                    .map((a) => CatalogArtist(id: 'name:$a', name: a))
                    .toList(),
              ),
            ),
          );
        }
        ids.add(id);
      }
      if (collection.sourceId == 'saved') {
        favorites.addAll(ids);
      } else {
        final id = 'spotify:${collection.sourceId}';
        playlists.removeWhere((p) => p.id == id);
        playlists.add(
          AuraPlaylist(id: id, name: collection.name, trackIds: ids),
        );
      }
    }
    notifyListeners();
    await save();
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
      if (i < 0) return;
      tracks[i] = tracks[i].copyWith(
        lyrics: lines,
        plainLyrics: '',
        lyricsSource: 'File LRC',
        lyricsSourceUrl: '',
      );
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
