import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:youtube_player_iframe/youtube_player_iframe.dart';

import '../../app/aura_controller.dart';
import '../../core/design/aura_design.dart';
import '../library/track_tile.dart';
import '../player/player_screen.dart' show timeLabel, openPlayer;
import 'online_track.dart';

Future<void> openOnlinePlayer(
  BuildContext context,
  AuraController c,
  OnlineTrack t, {
  List<OnlineTrack>? tracks,
}) async {
  final native = c.nativeTrackFor(t);
  final queue = tracks?.map(c.nativeTrackFor).toList();
  final loading = c.playTrack(native, contextTracks: queue);
  if (context.mounted) openPlayer(context, c);
  await loading;
}

Future<void> openEmbeddedVideo(
  BuildContext context,
  AuraController c,
  OnlineTrack t,
) async {
  await c.selectOnline(t);
  if (context.mounted) {
    await Navigator.push(
      context,
      MaterialPageRoute<void>(
        builder: (_) => OnlinePlayerScreen(controller: c),
      ),
    );
  }
}

class OnlinePlayerScreen extends StatefulWidget {
  const OnlinePlayerScreen({super.key, required this.controller});
  final AuraController controller;
  @override
  State<OnlinePlayerScreen> createState() => _OnlinePlayerScreenState();
}

class _OnlinePlayerScreenState extends State<OnlinePlayerScreen>
    with WidgetsBindingObserver {
  late final YoutubePlayerController _player;
  StreamSubscription<YoutubePlayerValue>? _events;
  bool _changing = false;
  PlayerState _previousState = PlayerState.unknown;
  Duration _position = Duration.zero;
  StreamSubscription<YoutubeVideoState>? _positions;
  String? _error;
  AuraController get c => widget.controller;
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _player = YoutubePlayerController.fromVideoId(
      videoId: c.onlineCurrent!.id,
      autoPlay: false,
      params: const YoutubePlayerParams(
        showControls: true,
        showFullscreenButton: true,
        origin: 'https://app.aura.personal',
        interfaceLanguage: 'it',
        captionLanguage: 'it',
        playsInline: true,
        strictRelatedVideos: true,
        videoStateUpdateInterval: 500,
      ),
    );
    _positions = _player.videoStateStream.listen((state) {
      _position = state.position;
    });
    _events = _player.stream.listen((value) {
      final ended =
          value.playerState == PlayerState.ended &&
          _previousState != PlayerState.ended;
      _previousState = value.playerState;
      if (ended &&
          !_changing &&
          youtubeReachedEnd(
            expectedId: c.onlineCurrentId!,
            actualId: value.metaData.videoId,
            duration: value.metaData.duration,
            position: _position,
          )) {
        _next(automatic: true);
      }
      if (value.metaData.videoId == c.onlineCurrentId &&
          value.metaData.title.isNotEmpty &&
          c.onlineCurrent!.title == 'Video YouTube') {
        c.refreshOnlineMetadata(
          OnlineTrack(
            id: c.onlineCurrentId!,
            title: value.metaData.title,
            artist: value.metaData.author,
            durationSeconds: value.metaData.duration.inSeconds,
          ),
        );
      }
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed) unawaited(_player.pauseVideo());
  }

  Future<void> _load(OnlineTrack t) async {
    if (_changing) return;
    setState(() {
      _changing = true;
      _error = null;
    });
    try {
      _position = Duration.zero;
      await c.selectOnline(t);
      await _player.loadVideoById(videoId: t.id);
    } catch (_) {
      if (mounted) {
        setState(
          () => _error = 'Impossibile aprire questo video. Riprova o scegli un altro risultato.',
        );
      }
    } finally {
      if (mounted) setState(() => _changing = false);
    }
  }

  Future<void> _next({bool automatic = false, bool previous = false}) async {
    final queue = c.onlineQueue;
    if (queue.isEmpty) return;
    final i = queue.indexOf(c.onlineCurrentId!);
    if (automatic && c.repeat == RepeatSetting.one) {
      await _load(c.onlineCurrent!);
      return;
    }
    if (automatic && i == queue.length - 1 && c.repeat == RepeatSetting.off) {
      return;
    }
    final candidates = queue.where((id) => id != c.onlineCurrentId).toList();
    final id = c.shuffle && candidates.isNotEmpty
        ? candidates[math.Random().nextInt(candidates.length)]
        : queue[(i + (previous ? -1 : 1) + queue.length) % queue.length];
    final t = c.onlineRecords[id];
    if (t != null) await _load(t);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    unawaited(_events?.cancel());
    unawaited(_positions?.cancel());
    unawaited(_player.close());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: c,
    builder: (_, _) {
      final t = c.onlineCurrent!;
      return Scaffold(
        appBar: AppBar(title: const Text('AURA · YouTube')),
        body: AuraBackground(
          color: auraViolet,
          child: SafeArea(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
              children: [
                // The actual video stays visible, unobscured and at least 200 px high.
                SizedBox(
                  height: math.max(
                    220,
                    (MediaQuery.sizeOf(context).width - 40) * 9 / 16,
                  ),
                  child: YoutubePlayer(
                    controller: _player,
                    aspectRatio: 16 / 9,
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            t.title,
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.w600,
                              height: 1.2,
                            ),
                          ),
                          const SizedBox(height: 9),
                          Text(
                            t.artist,
                            style: TextStyle(
                              color: context.muted,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      tooltip: 'Preferito YouTube',
                      onPressed: () => c.favoriteOnline(t),
                      icon: Icon(
                        c.onlineFavorites.contains(t.id)
                            ? Icons.favorite
                            : Icons.favorite_border,
                        color: auraPink,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                YoutubeValueBuilder(
                  controller: _player,
                  builder: (context, value) => Column(
                    children: [
                      if (value.hasError || _error != null)
                        AuraGlassSurface(
                          padding: const EdgeInsets.all(18),
                          child: Column(
                            children: [
                              Text(
                                _error ?? 'Questo video non è disponibile nel player incorporato. Puoi aprirlo su YouTube o scegliere un altro risultato.',
                              ),
                              Wrap(
                                spacing: 12,
                                children: [
                                  TextButton(
                                    onPressed: () => _load(t),
                                    child: const Text('Riprova'),
                                  ),
                                  TextButton(
                                    onPressed: () async {
                                      await _player.pauseVideo();
                                      await launchUrl(
                                        t.url,
                                        mode: LaunchMode.externalApplication,
                                      );
                                    },
                                    child: const Text('Apri su YouTube'),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      _OnlineProgress(
                        player: _player,
                        duration: value.metaData.duration,
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          IconButton(
                            tooltip: 'Casuale YouTube',
                            onPressed: c.toggleShuffle,
                            icon: Icon(
                              Icons.shuffle,
                              color: c.shuffle ? auraBlue : context.muted,
                            ),
                          ),
                          IconButton(
                            tooltip: 'Video precedente',
                            onPressed: _changing
                                ? null
                                : () => _next(previous: true),
                            icon: const Icon(
                              Icons.skip_previous_rounded,
                              size: 30,
                            ),
                          ),
                          GlassIcon(
                            size: 64,
                            icon: value.playerState == PlayerState.playing
                                ? Icons.pause_rounded
                                : Icons.play_arrow_rounded,
                            label: value.playerState == PlayerState.playing
                                ? 'Pausa video'
                                : 'Riproduci video',
                            active: true,
                            onPressed: value.hasError || _changing
                                ? null
                                : () {
                                    value.playerState == PlayerState.playing
                                        ? _player.pauseVideo()
                                        : _player.playVideo();
                                  },
                          ),
                          IconButton(
                            tooltip: 'Video successivo',
                            onPressed: _changing ? null : _next,
                            icon: const Icon(Icons.skip_next_rounded, size: 30),
                          ),
                          IconButton(
                            tooltip: 'Ripeti video: ${c.repeat.name}',
                            onPressed: c.cycleRepeat,
                            icon: Icon(
                              c.repeat == RepeatSetting.one
                                  ? Icons.repeat_one
                                  : Icons.repeat,
                              color: c.repeat == RepeatSetting.off
                                  ? context.muted
                                  : auraBlue,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 25),
                OutlinedButton.icon(
                  onPressed: () => addOnlineToPlaylist(context, c, t),
                  icon: const Icon(Icons.playlist_add),
                  label: const Text('Aggiungi a una playlist'),
                ),
                const SizedBox(height: 15),
                Text(
                  'Il player YouTube si ferma quando chiudi questa schermata o mandi l’app in background.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: context.muted,
                    fontSize: 12,
                    height: 1.5,
                  ),
                ),
                const SectionTitle('Coda YouTube'),
                ...c.onlineQueue
                    .map((id) => c.onlineRecords[id])
                    .whereType<OnlineTrack>()
                    .map(
                      (v) => ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: Icon(
                          v.id == t.id
                              ? Icons.graphic_eq
                              : Icons.play_circle_outline,
                        ),
                        title: Text(
                          v.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        subtitle: Text(
                          v.artist,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        onTap: () => _load(v),
                      ),
                    ),
              ],
            ),
          ),
        ),
      );
    },
  );
}

Future<void> addOnlineToPlaylist(
  BuildContext context,
  AuraController c,
  OnlineTrack t,
) => showModalBottomSheet<void>(
  context: context,
  showDragHandle: true,
  builder: (ctx) => SafeArea(
    child: ListView(
      shrinkWrap: true,
      children: [
        const Padding(
          padding: EdgeInsets.all(20),
          child: Text(
            'Playlist YouTube',
            style: TextStyle(fontSize: 23, fontWeight: FontWeight.w600),
          ),
        ),
        ListTile(
          leading: const Icon(Icons.add),
          title: const Text('Nuova playlist'),
          onTap: () async {
            final name = await askName(ctx);
            if (name != null) {
              c.addOnlineTrack(c.createOnlinePlaylist(name), t);
              if (ctx.mounted) Navigator.pop(ctx);
            }
          },
        ),
        ...c.onlinePlaylists.map(
          (p) => ListTile(
            title: Text(p.name),
            subtitle: Text('${p.trackIds.length} video'),
            onTap: () {
              c.addOnlineTrack(p, t);
              Navigator.pop(ctx);
            },
          ),
        ),
      ],
    ),
  ),
);

class OnlineMiniPlayer extends StatelessWidget {
  const OnlineMiniPlayer({super.key, required this.controller});
  final AuraController controller;
  @override
  Widget build(BuildContext context) {
    final t = controller.onlineCurrent!;
    return AuraGlassSurface(
      radius: 26,
      child: ListTile(
        dense: true,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 3),
        leading: const Icon(Icons.smart_display_outlined),
        title: Text(t.title, maxLines: 1, overflow: TextOverflow.ellipsis),
        subtitle: const Text('YouTube · tocca per aprire'),
        trailing: const Icon(Icons.play_arrow_rounded),
        onTap: () => openOnlinePlayer(context, controller, t),
      ),
    );
  }
}

class _OnlineProgress extends StatefulWidget {
  const _OnlineProgress({required this.player, required this.duration});
  final YoutubePlayerController player;
  final Duration duration;
  @override
  State<_OnlineProgress> createState() => _OnlineProgressState();
}

class _OnlineProgressState extends State<_OnlineProgress> {
  double? _drag;
  @override
  Widget build(BuildContext context) => StreamBuilder<YoutubeVideoState>(
    stream: widget.player.videoStateStream,
    builder: (_, snapshot) {
      final max = math.max(1, widget.duration.inMilliseconds).toDouble();
      final value =
          (_drag ?? (snapshot.data?.position.inMilliseconds ?? 0).toDouble())
              .clamp(0, max);
      return Column(
        children: [
          Slider(
            value: value.toDouble(),
            max: max,
            semanticFormatterCallback: (v) =>
                timeLabel(Duration(milliseconds: v.toInt())),
            onChanged: widget.duration > Duration.zero
                ? (v) => setState(() => _drag = v)
                : null,
            onChangeEnd: (v) {
              widget.player.seekTo(seconds: v / 1000, allowSeekAhead: true);
              setState(() => _drag = null);
            },
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                timeLabel(Duration(milliseconds: value.toInt())),
                style: TextStyle(color: context.muted, fontSize: 12),
              ),
              Text(
                timeLabel(widget.duration),
                style: TextStyle(color: context.muted, fontSize: 12),
              ),
            ],
          ),
        ],
      );
    },
  );
}
