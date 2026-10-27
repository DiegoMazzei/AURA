import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
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
  Future<void> configureEqualizer(bool enabled, List<double> gains) async {}
  Future<bool> equalizerProcessing() async => false;
  Track? get resolvedMetadata => null;
  void updateMetadata(Track track) {}
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
  final AndroidEqualizer _androidEq = AndroidEqualizer();
  late final AudioPlayer _player = AudioPlayer(
    userAgent: 'AURA/0.5 (Flutter; native audio)',
    useProxyForRequestHeaders: false,
    audioPipeline: AudioPipeline(
      androidAudioEffects: defaultTargetPlatform == TargetPlatform.android
          ? [_androidEq]
          : [],
    ),
  );
  static const _eqChannel = MethodChannel('aura/equalizer');
  bool _eqSupported = false;
  Future<void> _initEqualizer() async {
    try {
      if (defaultTargetPlatform == TargetPlatform.iOS) {
        final state = await _eqChannel.invokeMapMethod<String, dynamic>(
          'status',
        );
        _eqSupported = state?['supported'] == true;
      } else if (defaultTargetPlatform == TargetPlatform.android) {
        _eqSupported = true;
      }
      notifyListeners();
    } catch (_) {
      _eqSupported = false;
    }
  }

  @override
  Future<void> configureEqualizer(bool enabled, List<double> gains) async {
    if (defaultTargetPlatform == TargetPlatform.iOS) {
      await _eqChannel.invokeMethod<void>('configure', {
        'enabled': enabled,
        'gains': gains,
      });
    } else if (defaultTargetPlatform == TargetPlatform.android) {
      await _androidEq.setEnabled(enabled);
      if (!enabled) return;
      final params = await _androidEq.parameters;
      const frequencies = [60, 230, 910, 3600, 14000];
      for (final band in params.bands) {
        var closest = 0;
        for (var i = 1; i < 5; i++) {
          if ((frequencies[i] - band.centerFrequency).abs() <
              (frequencies[closest] - band.centerFrequency).abs()) {
            closest = i;
          }
        }
        await band.setGain(
          gains[closest].clamp(params.minDecibels, params.maxDecibels),
        );
      }
    } else {
      throw UnsupportedError('Equalizzatore non disponibile');
    }
  }

  @override
  Future<bool> equalizerProcessing() async {
    if (defaultTargetPlatform == TargetPlatform.android) return _eqSupported;
    final status = await _eqChannel.invokeMapMethod<String, dynamic>('status');
    return status?['attached'] == true && (status?['frames'] as num? ?? 0) > 0;
  }

  final List<StreamSubscription<dynamic>> _subscriptions = [];
  String? _error;
  Track? _resolvedMetadata;
  final YoutubeAudioResolver _youtube = YoutubeAudioResolver();
  @override
  Track? get resolvedMetadata => _resolvedMetadata;
  final AuraAudioHandler? mediaHandler;
  LocalAudioEngine({this.mediaHandler}) {
    unawaited(_initEqualizer());
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
    equalization: _eqSupported,
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
        title:
            !track.metadataEdited &&
                track.catalogIdentity == null &&
                resolved.title?.isNotEmpty == true
            ? resolved.title
            : null,
        artist:
            !track.metadataEdited &&
                track.catalogIdentity == null &&
                resolved.artist?.isNotEmpty == true
            ? resolved.artist
            : null,
        album:
            !track.metadataEdited &&
                track.catalogIdentity == null &&
                resolved.album?.isNotEmpty == true
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
  void updateMetadata(Track track) {
    final previous = mediaHandler?.mediaItem.value;
    if (previous == null || previous.id != track.id) return;
    mediaHandler?.mediaItem.add(
      previous.copyWith(
        title: track.title,
        artist: track.artist,
        album: track.album,
        artUri: track.artworkUrl == null ? null : Uri.parse(track.artworkUrl!),
      ),
    );
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
