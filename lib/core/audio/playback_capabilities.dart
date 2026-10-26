/// A provider declares what the UI may actually offer, independently of metadata.
class PlaybackCapabilities {
  const PlaybackCapabilities({
    required this.seeking,
    required this.offline,
    required this.audioOnly,
    required this.backgroundConfigured,
    required this.remoteControlsConfigured,
    this.equalization = false,
  });
  final bool seeking,
      offline,
      audioOnly,
      backgroundConfigured,
      remoteControlsConfigured,
      equalization;
}
