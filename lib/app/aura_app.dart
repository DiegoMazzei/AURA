import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../core/design/aura_design.dart';
import '../core/design/native_materials.dart';
import '../features/home/home_screen.dart';
import '../features/search/search_screen.dart';
import '../features/library/library_screen.dart';
import '../features/player/player_screen.dart';
import '../features/karaoke/karaoke_screen.dart';
import '../features/settings/settings_screen.dart';
import 'aura_controller.dart';

class AuraApp extends StatefulWidget {
  const AuraApp({super.key, required this.controller});
  final AuraController controller;
  @override
  State<AuraApp> createState() => _AuraAppState();
}

class _AuraAppState extends State<AuraApp> {
  late ThemeMode _mode;
  @override
  void initState() {
    super.initState();
    _mode = widget.controller.themeMode;
    widget.controller.addListener(_changed);
  }

  void _changed() {
    if (_mode != widget.controller.themeMode) {
      setState(() => _mode = widget.controller.themeMode);
    }
  }

  @override
  void dispose() {
    widget.controller.removeListener(_changed);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'AURA',
    debugShowCheckedModeBanner: false,
    theme: auraTheme(Brightness.light),
    darkTheme: auraTheme(Brightness.dark),
    themeMode: _mode,
    home: AuraShell(controller: widget.controller),
  );
}

class AuraShell extends StatefulWidget {
  const AuraShell({super.key, required this.controller});
  final AuraController controller;
  @override
  State<AuraShell> createState() => _AuraShellState();
}

class _AuraShellState extends State<AuraShell> with WidgetsBindingObserver {
  int _tab = 0;
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.inactive ||
        state == AppLifecycleState.paused) {
      unawaited(widget.controller.save());
    }
  }

  void _select(int tab) {
    HapticFeedback.selectionClick();
    setState(() => _tab = tab);
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: widget.controller,
    builder: (_, _) {
      final c = widget.controller;
      final pages = [
        HomeScreen(
          controller: c,
          onSearch: () => _select(1),
          onExplore: () => _select(1),
          onLibrary: () => _select(2),
          onKaraoke: () => Navigator.push(
            context,
            MaterialPageRoute<void>(
              builder: (_) => KaraokeScreen(controller: c),
            ),
          ),
          onSettings: () => Navigator.push(
            context,
            MaterialPageRoute<void>(
              builder: (_) => SettingsScreen(controller: c),
            ),
          ),
        ),
        SearchScreen(controller: c),
        LibraryScreen(controller: c),
      ];
      return AnnotatedRegion<SystemUiOverlayStyle>(
        value: context.isDark
            ? SystemUiOverlayStyle.light
            : SystemUiOverlayStyle.dark,
        child: Scaffold(
          body: AuraBackground(
            child: SafeArea(
              bottom: false,
              child: Stack(
                children: [
                  Positioned.fill(
                    child: Align(
                      alignment: Alignment.topCenter,
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 720),
                        child: Column(
                          children: [
                            if (c.error != null)
                              MaterialBanner(
                                content: Text(c.error!),
                                leading: const Icon(Icons.info_outline),
                                actions: [
                                  TextButton(
                                    onPressed: c.dismissError,
                                    child: const Text('Chiudi'),
                                  ),
                                ],
                              ),
                            Expanded(
                              child: !c.ready
                                  ? const Center(
                                      child: CircularProgressIndicator(),
                                    )
                                  : AnimatedSwitcher(
                                      duration:
                                          MediaQuery.disableAnimationsOf(
                                            context,
                                          )
                                          ? Duration.zero
                                          : const Duration(milliseconds: 200),
                                      child: KeyedSubtree(
                                        key: ValueKey(_tab),
                                        child: pages[_tab],
                                      ),
                                    ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    left: 20,
                    right: 20,
                    bottom: MediaQuery.paddingOf(context).bottom + 8,
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 680),
                        child: NativeMaterials.available
                            ? SizedBox(
                                height: c.hasCurrent ? 132 : 66,
                                child: ListenableBuilder(
                                  listenable: c.audio,
                                  builder: (_, _) => NativeGlassControl(
                                    kind: 'dock',
                                    config: {
                                      'tab': _tab,
                                      'hasCurrent': c.hasCurrent,
                                      'title': c.current.title,
                                      'artist': c.current.artist,
                                      'playing': c.audio.playing,
                                      'busy': c.busy,
                                      'dark': context.isDark,
                                      'progress': c.duration.inMilliseconds > 0
                                          ? c.position.inMilliseconds /
                                                c.duration.inMilliseconds
                                          : 0.0,
                                      'artwork':
                                          c.artwork?.cachedAlbum(
                                            c
                                                    .current
                                                    .catalogIdentity
                                                    ?.albumArtist ??
                                                c.current.artist,
                                            c.current.album,
                                          ) ??
                                          c.current.artworkUrl ??
                                          '',
                                    },
                                    onEvent: (method, args) {
                                      if (method == 'tab' &&
                                          args is int &&
                                          args >= 0 &&
                                          args < 3) {
                                        _select(args);
                                      }
                                      if (method == 'open') {
                                        openPlayer(context, c);
                                      }
                                      if (method == 'play') c.togglePlayback();
                                      if (method == 'next') c.next();
                                    },
                                  ),
                                ),
                              )
                            : _PortableDock(
                                controller: c,
                                selected: _tab,
                                onSelect: _select,
                              ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    },
  );
}

/// Standard platform-neutral controls on Android and older iOS; no fake glass.
class _PortableDock extends StatelessWidget {
  const _PortableDock({
    required this.controller,
    required this.selected,
    required this.onSelect,
  });
  final AuraController controller;
  final int selected;
  final ValueChanged<int> onSelect;
  @override
  Widget build(BuildContext context) => Column(
    mainAxisSize: MainAxisSize.min,
    children: [
      if (controller.hasCurrent) MiniPlayer(controller: controller),
      if (controller.hasCurrent) const SizedBox(height: 8),
      Material(
        color: context.isDark
            ? const Color(0xff202127)
            : const Color(0xffeaeaec),
        borderRadius: BorderRadius.circular(28),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 5),
          child: Row(
            children: List.generate(3, (i) {
              const labels = ['Ascolta', 'Cerca', 'Libreria'];
              const icons = [
                Icons.home_outlined,
                Icons.search_rounded,
                Icons.library_music_outlined,
              ];
              return Expanded(
                child: Semantics(
                  selected: i == selected,
                  button: true,
                  label: labels[i],
                  child: InkWell(
                    borderRadius: BorderRadius.circular(24),
                    onTap: () => onSelect(i),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 7),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            icons[i],
                            size: 23,
                            color: i == selected
                                ? Theme.of(context).colorScheme.primary
                                : context.muted,
                          ),
                          const SizedBox(height: 3),
                          Text(
                            labels[i],
                            style: TextStyle(
                              fontSize: 10,
                              color: i == selected
                                  ? context.ink
                                  : context.muted,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    ],
  );
}
