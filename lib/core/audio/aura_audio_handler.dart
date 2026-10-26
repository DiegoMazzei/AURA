import 'package:audio_service/audio_service.dart';

/// Bridges OS media commands to the same controller used by the Flutter UI.
class AuraAudioHandler extends BaseAudioHandler {
  Future<void> Function()? playAction, pauseAction, nextAction, previousAction;
  Future<void> Function(Duration)? seekAction;
  @override
  Future<void> play() async {
    await playAction?.call();
  }

  @override
  Future<void> pause() async {
    await pauseAction?.call();
  }

  @override
  Future<void> skipToNext() async {
    await nextAction?.call();
  }

  @override
  Future<void> skipToPrevious() async {
    await previousAction?.call();
  }

  @override
  Future<void> seek(Duration position) async {
    await seekAction?.call(position);
  }

  @override
  Future<void> stop() async {
    await pauseAction?.call();
    await super.stop();
  }
}
