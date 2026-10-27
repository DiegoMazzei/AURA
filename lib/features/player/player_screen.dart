import '../catalog/catalog_screen.dart' show openTrackArtist;

import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../app/aura_controller.dart';
import '../../core/design/aura_design.dart';
import '../../core/artwork/music_image.dart';
import '../karaoke/karaoke_screen.dart';
import '../youtube/online_track.dart';
import '../youtube/online_player_screen.dart' show openEmbeddedVideo;
import '../library/track_tile.dart';

String timeLabel(Duration d) =>
    '${d.inMinutes}:${(d.inSeconds % 60).toString().padLeft(2, '0')}';

void openPlayer(BuildContext context, AuraController controller) {
  Navigator.of(context).push(
    PageRouteBuilder<void>(
      opaque: true,
      transitionDuration: MediaQuery.disableAnimationsOf(context)
          ? Duration.zero
          : const Duration(milliseconds: 520),
      reverseTransitionDuration: const Duration(milliseconds: 360),
      pageBuilder: (_, _, _) => PlayerScreen(controller: controller),
      transitionsBuilder: (_, animation, _, child) => SlideTransition(
        position: Tween<Offset>(begin: const Offset(0, 1), end: Offset.zero)
            .animate(
              CurvedAnimation(
                parent: animation,
                curve: Curves.easeOutCubic,
                reverseCurve: Curves.easeInCubic,
              ),
            ),
        child: child,
      ),
    ),
  );
}

class MiniPlayer extends StatelessWidget {
  const MiniPlayer({super.key, required this.controller});
  final AuraController controller;
  @override
  Widget build(BuildContext context) {
    final c = controller;
    return AuraGlassSurface(
      radius: 26,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 7, 7, 3),
            child: Row(
              children: [
                Expanded(
                  child: Semantics(
                    button: true,
                    label: 'Apri player: ${c.current.title}',
                    child: InkWell(
                      onTap: () => openPlayer(context, c),
                      borderRadius: BorderRadius.circular(20),
                      child: Row(
                        children: [
                          Hero(
                            tag: 'current-art',
                            child: CosmicCover(
                              color: Color(c.current.color),
                              imageUrl: c.current.artworkUrl,
                              size: 45,
                              radius: 14,
                            ),
                          ),
                          const SizedBox(width: 11),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  c.current.title,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                Text(
                                  c.current.artist,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: context.muted,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                PlayButton(controller: c, mini: true),
                IconButton(
                  tooltip: 'Brano successivo',
                  onPressed: c.busy ? null : c.next,
                  icon: const Icon(Icons.skip_next_rounded, size: 26),
                ),
              ],
            ),
          ),
          ListenableBuilder(
            listenable: c.audio,
            builder: (_, _) => ClipRRect(
              borderRadius: BorderRadius.circular(2),
              child: LinearProgressIndicator(
                minHeight: 2,
                value: c.duration.inMilliseconds <= 0
                    ? 0
                    : (c.position.inMilliseconds / c.duration.inMilliseconds)
                          .clamp(0, 1),
                color: Color(c.current.color),
                backgroundColor: Colors.transparent,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class PlayButton extends StatelessWidget {
  const PlayButton({super.key, required this.controller, this.mini = false});
  final AuraController controller;
  final bool mini;
  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: controller.audio,
    builder: (_, _) {
      final playing = controller.audio.playing;
      if (mini) {
        return IconButton(
          tooltip: playing ? 'Pausa' : 'Riproduci',
          onPressed: controller.busy ? null : controller.togglePlayback,
          icon: controller.busy
              ? const SizedBox(
                  width: 19,
                  height: 19,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Icon(
                  playing ? Icons.pause_rounded : Icons.play_arrow_rounded,
                  size: 28,
                ),
        );
      }
      return SizedBox(
        width: 78,
        height: 78,
        child: IconButton(
          tooltip: playing ? 'Pausa' : 'Riproduci',
          onPressed: controller.busy ? null : controller.togglePlayback,
          icon: controller.busy
              ? const CircularProgressIndicator(strokeWidth: 2)
              : Icon(
                  playing ? Icons.pause_rounded : Icons.play_arrow_rounded,
                  size: 58,
                ),
        ),
      );
    },
  );
}

class TrackProgress extends StatefulWidget {
  const TrackProgress({super.key, required this.controller});
  final AuraController controller;
  @override
  State<TrackProgress> createState() => _TrackProgressState();
}

class _TrackProgressState extends State<TrackProgress> {
  double? _drag;
  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: widget.controller.audio,
    builder: (_, _) {
      final c = widget.controller;
      final max = math.max(1, c.duration.inMilliseconds).toDouble();
      final value = _drag ?? c.position.inMilliseconds.toDouble().clamp(0, max);
      return Column(
        children: [
          SliderTheme(
            data: SliderTheme.of(context).copyWith(padding: EdgeInsets.zero),
            child: Slider(
              semanticFormatterCallback: (v) =>
                  timeLabel(Duration(milliseconds: v.toInt())),
              min: 0,
              max: max,
              value: value.clamp(0, max),
              onChanged: c.duration > Duration.zero
                  ? (v) => setState(() => _drag = v)
                  : null,
              onChangeEnd: (v) {
                c.seek(Duration(milliseconds: v.toInt()));
                setState(() => _drag = null);
              },
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                timeLabel(Duration(milliseconds: value.toInt())),
                style: TextStyle(fontSize: 11, color: context.muted),
              ),
              Text(
                '-${timeLabel(Duration(milliseconds: (max - value).toInt()))}',
                style: TextStyle(fontSize: 11, color: context.muted),
              ),
            ],
          ),
        ],
      );
    },
  );
}

class PlayerScreen extends StatelessWidget {
  const PlayerScreen({super.key, required this.controller});
  final AuraController controller;
  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: controller,
    builder: (_, _) {
      final c = controller;
      return Scaffold(
        body: AuraBackground(
          artwork: true,
          color: Color(c.current.color),
          child: SafeArea(
            child: LayoutBuilder(
              builder: (ctx, constraints) => SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(28, 12, 28, 26),
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    minHeight: constraints.maxHeight - 38,
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          GlassIcon(
                            icon: Icons.keyboard_arrow_down_rounded,
                            label: 'Chiudi player',
                            onPressed: () => Navigator.pop(context),
                          ),
                          Expanded(
                            child: Column(
                              children: [
                                Text(
                                  'AURA',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w300,
                                    letterSpacing: 3,
                                    color: context.muted,
                                  ),
                                ),
                                const SizedBox(height: 3),
                                Text(
                                  c.current.isAsset
                                      ? 'ORIGINALS · DEMO'
                                      : c.current.isYoutube
                                      ? 'IN RIPRODUZIONE'
                                      : 'LA TUA MUSICA',
                                  style: TextStyle(
                                    fontSize: 8,
                                    letterSpacing: 1.6,
                                    color: context.muted,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          GlassIcon(
                            icon: Icons.graphic_eq_rounded,
                            label: 'Impostazioni audio',
                            onPressed: () => showAudioSettings(context, c),
                          ),
                        ],
                      ),
                      if (c.error != null)
                        AuraGlassSurface(
                          padding: const EdgeInsets.all(14),
                          child: Column(
                            children: [
                              Text(
                                c.error!,
                                style: const TextStyle(fontSize: 13),
                              ),
                              Wrap(
                                spacing: 12,
                                children: [
                                  TextButton(
                                    onPressed: c.busy
                                        ? null
                                        : () => c.playTrack(c.current),
                                    child: const Text('Riprova'),
                                  ),
                                  if (c.current.isYoutube)
                                    TextButton(
                                      onPressed: () => openEmbeddedVideo(
                                        context,
                                        c,
                                        OnlineTrack(
                                          id: c.current.source,
                                          title: c.current.title,
                                          artist: c.current.artist,
                                        ),
                                      ),
                                      child: const Text('Apri come video'),
                                    ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      const SizedBox(height: 26),
                      Hero(
                        tag: 'current-art',
                        child: AnimatedSwitcher(
                          duration: const Duration(milliseconds: 500),
                          child: MusicImage(
                            key: ValueKey(c.currentId),
                            controller: c,
                            artist:
                                c.current.catalogIdentity?.albumArtist ??
                                c.current.artist,
                            album: c.current.album,
                            fallbackUrl: c.current.artworkUrl,
                            size: math.min(constraints.maxWidth - 56, 390),
                            radius: 16,
                          ),
                        ),
                      ),
                      const SizedBox(height: 28),
                      Row(
                        children: [
                          Expanded(
                            child: AnimatedSwitcher(
                              duration: const Duration(milliseconds: 250),
                              child: Column(
                                key: ValueKey(c.currentId),
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    c.current.title,
                                    style: const TextStyle(
                                      fontSize: 29,
                                      fontWeight: FontWeight.w600,
                                      letterSpacing: -.8,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Wrap(
                                    spacing: 8,
                                    children: [
                                      if (c
                                              .current
                                              .catalogIdentity
                                              ?.artists
                                              .isNotEmpty ==
                                          true)
                                        for (final artist
                                            in c
                                                .current
                                                .catalogIdentity!
                                                .artists)
                                          InkWell(
                                            onTap: () => openTrackArtist(
                                              context,
                                              c,
                                              c.current,
                                              creditedArtist: artist,
                                            ),
                                            child: Padding(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    vertical: 6,
                                                  ),
                                              child: Text(
                                                artist.name,
                                                style: TextStyle(
                                                  color: context.muted,
                                                  fontSize: 17,
                                                  decoration:
                                                      TextDecoration.underline,
                                                  decorationColor: context.muted
                                                      .withValues(alpha: .4),
                                                ),
                                              ),
                                            ),
                                          ),
                                      if (c
                                              .current
                                              .catalogIdentity
                                              ?.artists
                                              .isNotEmpty !=
                                          true)
                                        InkWell(
                                          onTap: () => openTrackArtist(
                                            context,
                                            c,
                                            c.current,
                                          ),
                                          child: Padding(
                                            padding: const EdgeInsets.symmetric(
                                              vertical: 6,
                                            ),
                                            child: Text(
                                              c.current.artist,
                                              style: TextStyle(
                                                color: context.muted,
                                                fontSize: 17,
                                                decoration:
                                                    TextDecoration.underline,
                                                decorationColor: context.muted
                                                    .withValues(alpha: .4),
                                              ),
                                            ),
                                          ),
                                        ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                          GlassIcon(
                            icon: c.favorites.contains(c.currentId)
                                ? Icons.favorite
                                : Icons.favorite_border,
                            label: c.favorites.contains(c.currentId)
                                ? 'Rimuovi dai preferiti'
                                : 'Aggiungi ai preferiti',
                            active: c.favorites.contains(c.currentId),
                            onPressed: () => c.toggleFavorite(c.currentId),
                          ),
                        ],
                      ),
                      const SizedBox(height: 18),
                      TrackProgress(controller: c),
                      const SizedBox(height: 19),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          IconButton(
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints.tightFor(
                              width: 44,
                              height: 48,
                            ),
                            tooltip: c.shuffle
                                ? 'Disattiva casuale'
                                : 'Riproduzione casuale',
                            onPressed: c.toggleShuffle,
                            icon: Icon(
                              Icons.shuffle_rounded,
                              color: c.shuffle
                                  ? Theme.of(context).colorScheme.primary
                                  : context.muted,
                            ),
                          ),
                          IconButton(
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints.tightFor(
                              width: 44,
                              height: 48,
                            ),
                            tooltip: 'Brano precedente',
                            onPressed: c.busy ? null : c.previous,
                            icon: const Icon(
                              Icons.skip_previous_rounded,
                              size: 35,
                            ),
                          ),
                          PlayButton(controller: c),
                          IconButton(
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints.tightFor(
                              width: 44,
                              height: 48,
                            ),
                            tooltip: 'Brano successivo',
                            onPressed: c.busy ? null : c.next,
                            icon: const Icon(Icons.skip_next_rounded, size: 35),
                          ),
                          IconButton(
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints.tightFor(
                              width: 44,
                              height: 48,
                            ),
                            tooltip: 'Ripetizione: ${c.repeat.name}',
                            onPressed: c.cycleRepeat,
                            icon: Icon(
                              c.repeat == RepeatSetting.one
                                  ? Icons.repeat_one_rounded
                                  : Icons.repeat_rounded,
                              color: c.repeat == RepeatSetting.off
                                  ? context.muted
                                  : Theme.of(context).colorScheme.primary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 28),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _PlayerAction(
                            Icons.lyrics_outlined,
                            'Testi',
                            () => Navigator.push(
                              context,
                              MaterialPageRoute<void>(
                                builder: (_) => KaraokeScreen(controller: c),
                              ),
                            ),
                          ),
                          _PlayerAction(
                            Icons.mic_none_rounded,
                            'Karaoke',
                            () => Navigator.push(
                              context,
                              MaterialPageRoute<void>(
                                builder: (_) => KaraokeScreen(controller: c),
                              ),
                            ),
                          ),
                          _PlayerAction(
                            Icons.queue_music_rounded,
                            'Coda',
                            () => openQueue(context, c),
                          ),
                          _PlayerAction(
                            Icons.playlist_add_rounded,
                            'Aggiungi',
                            () => addToPlaylist(context, c, c.current),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      );
    },
  );
}

class _PlayerAction extends StatelessWidget {
  const _PlayerAction(this.icon, this.label, this.onTap);
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => Expanded(
    child: Column(
      children: [
        GlassIcon(icon: icon, label: label, onPressed: onTap, size: 50),
        const SizedBox(height: 9),
        Text(
          label,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 12),
        ),
      ],
    ),
  );
}

void openQueue(BuildContext context, AuraController c) => Navigator.push(
  context,
  MaterialPageRoute<void>(
    builder: (_) => ListenableBuilder(
      listenable: c,
      builder: (context, _) => Scaffold(
        appBar: AppBar(title: const Text('Coda di riproduzione')),
        body: AuraBackground(
          color: Color(c.current.color),
          child: ReorderableListView(
            padding: const EdgeInsets.fromLTRB(24, 10, 24, 24),
            onReorderItem: c.reorderQueue,
            header: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  spacing: 8,
                  children: [
                    FilterChip(
                      label: const Text('Casuale'),
                      selected: c.shuffle,
                      onSelected: (_) => c.toggleShuffle(),
                    ),
                    ActionChip(
                      label: Text(
                        'Ripeti: ${['no', 'tutti', 'uno'][c.repeat.index]}',
                      ),
                      onPressed: c.cycleRepeat,
                    ),
                    ActionChip(
                      label: const Text('Salva playlist'),
                      onPressed: () async {
                        final name = await askName(context);
                        if (name != null) {
                          final p = c.createPlaylist(name);
                          for (final id in c.queue) {
                            c.addToPlaylist(p, id);
                          }
                        }
                      },
                    ),
                  ],
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  child: Text(
                    'Tieni premuto per cambiare l’ordine.',
                    style: TextStyle(color: context.muted, fontSize: 12),
                  ),
                ),
              ],
            ),
            children: [
              for (final t in c.queueTracks)
                TrackTile(
                  key: ValueKey(t.id),
                  track: t,
                  controller: c,
                  trailing: t.id == c.currentId
                      ? const Icon(Icons.graphic_eq_rounded)
                      : IconButton(
                          tooltip: 'Rimuovi dalla coda',
                          onPressed: () => c.removeFromQueue(t.id),
                          icon: const Icon(Icons.close_rounded),
                        ),
                ),
            ],
          ),
        ),
      ),
    ),
  ),
);

void showAudioSettings(BuildContext context, AuraController c) =>
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (_) => ListenableBuilder(
        listenable: c,
        builder: (context, _) => SafeArea(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Il tuo suono',
                    style: TextStyle(fontSize: 26, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 24),
                  const Text('Volume di AURA'),
                  Row(
                    children: [
                      const Icon(Icons.volume_down_outlined),
                      Expanded(
                        child: Slider(value: c.volume, onChanged: c.setVolume),
                      ),
                      const Icon(Icons.volume_up_outlined),
                    ],
                  ),
                  const SizedBox(height: 18),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Equalizzatore'),
                    value: c.equalizerEnabled,
                    onChanged: c.audio.capabilities.equalization
                        ? (v) => c.setEqualizer(enabled: v)
                        : null,
                  ),
                  if (c.audio.capabilities.equalization) ...[
                    Wrap(
                      spacing: 8,
                      children: [
                        ActionChip(
                          label: const Text('Neutro'),
                          onPressed: () =>
                              c.setEqualizer(preset: [0, 0, 0, 0, 0]),
                        ),
                        ActionChip(
                          label: const Text('Bassi'),
                          onPressed: () => c.setEqualizer(
                            enabled: true,
                            preset: [6, 3, 0, -1, 1],
                          ),
                        ),
                        ActionChip(
                          label: const Text('Voce'),
                          onPressed: () => c.setEqualizer(
                            enabled: true,
                            preset: [-2, -1, 3, 4, 1],
                          ),
                        ),
                      ],
                    ),
                    for (var i = 0; i < 5; i++)
                      Row(
                        children: [
                          SizedBox(
                            width: 48,
                            child: Text(['60', '230', '910', '3.6k', '14k'][i]),
                          ),
                          Expanded(
                            child: Slider(
                              min: -12,
                              max: 12,
                              divisions: 24,
                              value: c.equalizerGains[i],
                              onChanged: c.equalizerEnabled
                                  ? (v) => c.setEqualizer(band: i, gain: v)
                                  : null,
                            ),
                          ),
                          SizedBox(
                            width: 48,
                            child: Text('${c.equalizerGains[i].round()} dB'),
                          ),
                        ],
                      ),
                  ] else
                    Text(
                      'Equalizzatore non disponibile su questo dispositivo.',
                      style: TextStyle(color: context.muted),
                    ),
                  if (c.equalizerEnabled)
                    FutureBuilder<bool>(
                      future: c.audio.equalizerProcessing(),
                      builder: (_, snapshot) => Text(
                        snapshot.data == true
                            ? 'Filtro applicato al brano'
                            : 'In attesa del flusso audio…',
                        style: TextStyle(color: context.muted, fontSize: 12),
                      ),
                    ),
                  const SizedBox(height: 12),
                  Text(
                    'L’uscita audio si sceglie dai controlli di sistema.',
                    style: TextStyle(color: context.muted, fontSize: 12),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
