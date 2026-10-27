import 'dart:async';

import 'package:flutter/material.dart';
import 'package:audio_service/audio_service.dart';
import 'package:audio_session/audio_session.dart';

import 'app/aura_app.dart';
import 'core/design/native_materials.dart';
import 'core/catalog/music_json_client.dart';
import 'core/catalog/artist_directory.dart';
import 'core/catalog/musicbrainz_catalog.dart';
import 'core/lyrics/lyrics_provider.dart';
import 'app/aura_controller.dart';
import 'core/audio/audio_engine.dart';
import 'core/audio/aura_audio_handler.dart';
import 'core/storage/library_store.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await NativeMaterials.initialize();
  AuraAudioHandler? handler;
  String? startupError;
  try {
    handler = await AudioService.init<AuraAudioHandler>(
      builder: AuraAudioHandler.new,
      config: const AudioServiceConfig(
        androidNotificationChannelId: 'aura.music.playback',
        androidNotificationChannelName: 'Riproduzione AURA',
        androidNotificationOngoing: true,
      ),
    );
    final session = await AudioSession.instance;
    await session.configure(const AudioSessionConfiguration.music());
    debugPrint('AURA_MEDIA_SESSION_READY');
  } catch (error) {
    debugPrint('AURA_MEDIA_SESSION_FAILED: $error');
    startupError =
        'I controlli audio di sistema non sono disponibili in questa sessione.';
  }
  final musicData = PublicMusicJsonClient();
  final controller = AuraController(
    metadataCatalog: ResilientMetadataCatalog(musicData),
    artistDirectory: AppleArtistDirectory(musicData),
    lyricsProvider: LrclibLyricsProvider(musicData),
    audio: LocalAudioEngine(mediaHandler: handler),
    store: DeviceLibraryStore(),
  );
  if (handler != null) {
    handler.playAction = () => controller.playTrack(controller.current);
    handler.pauseAction = () async {
      await controller.audio.pause();
      await controller.save();
    };
    handler.nextAction = controller.next;
    handler.previousAction = controller.previous;
    handler.seekAction = controller.seek;
  }
  runApp(AuraApp(controller: controller));
  await controller.initialize();
  if (startupError != null) {
    controller.error = startupError;
    controller.notifyStartupIssue();
  }
}
