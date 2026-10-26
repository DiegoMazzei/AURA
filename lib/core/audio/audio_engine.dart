import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';
import 'package:audio_service/audio_service.dart';

import 'aura_audio_handler.dart';
import 'playback_capabilities.dart';
import 'youtube_audio_resolver.dart';

import '../../shared/models/music.dart';
import '../storage/library_store.dart';

abstract class AudioEngine extends ChangeNotifier {
  PlaybackCapabilities get capabilities => const PlaybackCapabilities(
    seeking: true,
    offline: true,
    audioOnly: true,
    backgroundConfigured: false,
    remoteControlsConfigured: false,
  );
  Track? get resolvedMetadata => null;
  Duration get position;
  Duration get duration;
  bool get playing;
  String? get error;
  VoidCallback? onComplete;
  Future<void> load(Track track);
  void play();
  Future<void> pause();
  Future<void> seek(Duration position);
  Future<void> setVolume(double value);
}

class LocalAudioEngine extends AudioEngine {
  final AudioPlayer _player = AudioPlayer(
    userAgent: 'AURA/0.1 (Flutter; native audio)',
    useProxyForRequestHeaders: false,
  );
  final List<StreamSubscription<dynamic>> _subscriptions = [];
  String? _error;
  Track? _resolvedMetadata;
  final YoutubeAudioResolver _youtube = YoutubeAudioResolver();
  @override
  Track? get resolvedMetadata => _resolvedMetadata;
  final AuraAudioHandler? mediaHandler;
  LocalAudioEngine({this.mediaHandler}) {
    _subscriptions.add(
      _player.playbackEventStream.listen((event) {
        mediaHandler?.playbackState.add(
          PlaybackState(
            controls: [
              MediaControl.skipToPrevious,
              _player.playing ? MediaControl.pause : MediaControl.play,
              MediaControl.skipToNext,
            ],
            systemActions: const {MediaAction.seek},
            androidCompactActionIndices: const [0, 1, 2],
            processingState: {
              ProcessingState.idle: AudioProcessingState.idle,
              ProcessingState.loading: AudioProcessingState.loading,
              ProcessingState.buffering: AudioProcessingState.buffering,
              ProcessingState.ready: AudioProcessingState.ready,
              ProcessingState.completed: AudioProcessingState.completed,
            }[_player.processingState]!,
            playing: _player.playing,
            updatePosition: _player.position,
            bufferedPosition: _player.bufferedPosition,
            speed: _player.speed,
          ),
        );
      }, onError: (Object e) {}),
    );
    _subscriptions.add(_player.positionStream.listen((_) => notifyListeners()));
    _subscriptions.add(_player.durationStream.listen((_) => notifyListeners()));
    _subscriptions.add(
      _player.playerStateStream.listen((state) {
        notifyListeners();
        if (state.processingState == ProcessingState.completed) {
          onComplete?.call();
        }
      }),
    );
    _subscriptions.add(
      _player.errorStream.listen((e) {
        _error = 'Riproduzione interrotta. Riprova o scegli un altro file.';
        notifyListeners();
      }),
    );
  }
  @override
  PlaybackCapabilities get capabilities => PlaybackCapabilities(
    seeking: true,
    offline: true,
    audioOnly: true,
    backgroundConfigured: mediaHandler != null,
    remoteControlsConfigured: mediaHandler != null,
  );
  @override
  Duration get position => _player.position;
  @override
  Duration get duration => _player.duration ?? Duration.zero;
  @override
  bool get playing =>
      _player.playing && _player.processingState != ProcessingState.completed;
  @override
  String? get error => _error;
  @override
  Future<void> load(Track track) async {
    _error = null;
    _resolvedMetadata = null;
    await _player.pause();
    mediaHandler?.mediaItem.add(
      MediaItem(
        id: track.id,
        title: track.title,
        artist: track.artist,
        album: track.isAsset ? 'AURA Originals' : 'La tua libreria',
        artUri: track.artworkUrl == null ? null : Uri.parse(track.artworkUrl!),
        duration: track.durationSeconds > 0
            ? Duration(seconds: track.durationSeconds)
            : null,
      ),
    );
    if (track.isYoutube) {
      final resolved = await _youtube.resolve(track.source);
      await _player
          .setUrl(resolved.uri.toString())
          .timeout(const Duration(seconds: 25));
      _resolvedMetadata = track.copyWith(
        title: !track.metadataEdited && resolved.title?.isNotEmpty == true
            ? resolved.title
            : null,
        artist: !track.metadataEdited && resolved.artist?.isNotEmpty == true
            ? resolved.artist
            : null,
        album: !track.metadataEdited && resolved.album?.isNotEmpty == true
            ? resolved.album
            : null,
        durationSeconds: _player.duration?.inSeconds ?? track.durationSeconds,
      );
    } else if (track.isAsset) {
      await _player.setAsset(track.source);
    } else {
      await _player.setFilePath(await DeviceLibraryStore.resolve(track.source));
    }
    final old = mediaHandler?.mediaItem.value;
    if (old != null) {
      mediaHandler?.mediaItem.add(
        old.copyWith(
          duration: _player.duration,
          title: _resolvedMetadata?.title ?? track.title,
          artist: _resolvedMetadata?.artist ?? track.artist,
          album: _resolvedMetadata?.album.isNotEmpty == true
              ? _resolvedMetadata!.album
              : old.album,
        ),
      );
    }
  }

  @override
  void play() {
    unawaited(
      _player.play().catchError((Object e) {
        _error = 'Impossibile riprodurre questo audio.';
        notifyListeners();
      }),
    );
  }

  @override
  Future<void> pause() => _player.pause();
  @override
  Future<void> seek(Duration position) => _player.seek(position);
  @override
  Future<void> setVolume(double value) => _player.setVolume(value);
  @override
  void dispose() {
    mediaHandler?.playbackState.add(
      PlaybackState(processingState: AudioProcessingState.idle),
    );
    for (final sub in _subscriptions) {
      unawaited(sub.cancel());
    }
    unawaited(_player.dispose());
    super.dispose();
  }
}
