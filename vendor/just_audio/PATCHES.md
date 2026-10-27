# AURA patch

Upstream: just_audio 0.10.6, MIT (see LICENSE).

AudioPlayer.m posts AuraAudioItemReady with the ready AVPlayerItem. AURA installs
its audio processing tap after the item becomes ready. No transport, stream
selection, authentication or background playback behavior is modified.
