import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../core/design/aura_design.dart';
import '../features/home/home_screen.dart';
import '../features/search/search_screen.dart';
import '../features/library/library_screen.dart';
import '../features/player/player_screen.dart';
import '../features/karaoke/karaoke_screen.dart';
import '../features/settings/settings_screen.dart';
import 'aura_controller.dart';
import '../features/youtube/online_player_screen.dart';

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
          onExplore: () => _select(2),
          onLibrary: () => _select(3),
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
        SearchScreen(controller: c, explore: true),
        LibraryScreen(controller: c),
      ];
      return AnnotatedRegion<SystemUiOverlayStyle>(
        value: context.isDark
            ? SystemUiOverlayStyle.light
            : SystemUiOverlayStyle.dark,
        child: Scaffold(
          body: AuraBackground(
            artwork: _tab == 0 || _tab == 2,
            color: Color(c.current.color),
            child: SafeArea(
              bottom: false,
              child: Center(
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
                            ? const Center(child: CircularProgressIndicator())
                            : AnimatedSwitcher(
                                duration:
                                    MediaQuery.disableAnimationsOf(context)
                                    ? Duration.zero
                                    : const Duration(milliseconds: 260),
                                child: KeyedSubtree(
                                  key: ValueKey(_tab),
                                  child: pages[_tab],
                                ),
                              ),
                      ),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            c.onlineCurrent == null
                                ? MiniPlayer(controller: c)
                                : OnlineMiniPlayer(controller: c),
                            const SizedBox(height: 9),
                            AuraGlassSurface(
                              radius: 32,
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 13,
                                  vertical: 5,
                                ),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceAround,
                                  children: List.generate(4, (i) {
                                    const icons = [
                                      Icons.home_outlined,
                                      Icons.search_rounded,
                                      Icons.explore_outlined,
                                      Icons.library_music_outlined,
                                    ];
                                    const labels = [
                                      'Home',
                                      'Cerca',
                                      'Esplora',
                                      'Libreria',
                                    ];
                                    return Expanded(
                                      child: Semantics(
                                        selected: i == _tab,
                                        button: true,
                                        label: labels[i],
                                        child: InkWell(
                                          onTap: () => _select(i),
                                          borderRadius: BorderRadius.circular(
                                            24,
                                          ),
                                          child: AnimatedContainer(
                                            duration: const Duration(
                                              milliseconds: 230,
                                            ),
                                            margin: const EdgeInsets.symmetric(
                                              horizontal: 3,
                                            ),
                                            padding: const EdgeInsets.symmetric(
                                              vertical: 8,
                                            ),
                                            decoration: BoxDecoration(
                                              borderRadius:
                                                  BorderRadius.circular(24),
                                              gradient: i == _tab
                                                  ? RadialGradient(
                                                      colors: [
                                                        auraBlue.withValues(
                                                          alpha: context.isDark
                                                              ? .7
                                                              : .45,
                                                        ),
                                                        auraBlue.withValues(
                                                          alpha: .07,
                                                        ),
                                                      ],
                                                    )
                                                  : null,
                                            ),
                                            child: Column(
                                              children: [
                                                Icon(icons[i], size: 23),
                                                const SizedBox(height: 2),
                                                Text(
                                                  labels[i],
                                                  style: const TextStyle(
                                                    fontSize: 9,
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
                            SizedBox(
                              height: MediaQuery.paddingOf(context).bottom + 8,
                            ),
                          ],
                        ),
                      ),
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
