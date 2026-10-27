import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../app/aura_controller.dart';
import '../../shared/models/music.dart';
import '../../core/lyrics/lyrics_provider.dart';
import '../../core/design/aura_design.dart';

Future<void> findLyrics(BuildContext context, AuraController c, Track t) =>
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (_) => _LyricsSearch(controller: c, track: t),
    );

class _LyricsSearch extends StatefulWidget {
  const _LyricsSearch({required this.controller, required this.track});
  final AuraController controller;
  final Track track;
  @override
  State<_LyricsSearch> createState() => _LyricsSearchState();
}

class _LyricsSearchState extends State<_LyricsSearch> {
  late Future<List<LyricsCandidate>> _results = _search();
  String? _linkError;
  Future<List<LyricsCandidate>> _search() async =>
      await widget.controller.lyricsProvider?.search(widget.track) ?? [];
  Future<void> _genius() async {
    final query = '${widget.track.artist} ${widget.track.title}';
    try {
      if (!await launchUrl(
        Uri.https('genius.com', '/search', {'q': query}),
        mode: LaunchMode.externalApplication,
      )) {
        if (mounted) setState(() => _linkError = 'Impossibile aprire Genius.');
      }
    } catch (_) {
      if (mounted) setState(() => _linkError = 'Impossibile aprire Genius.');
    }
  }

  @override
  Widget build(BuildContext context) => SafeArea(
    child: SizedBox(
      height: MediaQuery.sizeOf(context).height * .78,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 24, 12, 6),
            child: Row(
              children: [
                const Expanded(
                  child: Text(
                    'Le parole della musica',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -.6,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Text(
              'Scegli la versione corretta. I testi sincronizzati abilitano il karaoke.',
              style: TextStyle(color: context.muted),
            ),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: FutureBuilder<List<LyricsCandidate>>(
              future: _results,
              builder: (context, snapshot) {
                if (snapshot.connectionState != ConnectionState.done) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text('I testi non sono disponibili al momento.'),
                        TextButton(
                          onPressed: () => setState(() => _results = _search()),
                          child: const Text('Riprova'),
                        ),
                      ],
                    ),
                  );
                }
                final results = snapshot.data ?? [];
                if (results.isEmpty) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(24),
                      child: Text(
                        'Nessun testo trovato. Puoi consultare Genius o importare il tuo file LRC.',
                        textAlign: TextAlign.center,
                      ),
                    ),
                  );
                }
                return ListView.builder(
                  itemCount: results.length,
                  itemBuilder: (context, i) {
                    final r = results[i];
                    return ListTile(
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 6,
                      ),
                      leading: Icon(
                        r.instrumental
                            ? Icons.music_note_outlined
                            : r.synchronized
                            ? Icons.lyrics_outlined
                            : Icons.notes_rounded,
                      ),
                      title: Text(r.title),
                      subtitle: Text(
                        '${r.artist} · ${r.album}\n${r.instrumental
                            ? 'Strumentale'
                            : r.synchronized
                            ? 'Sincronizzato · karaoke'
                            : 'Solo testo'} · LRCLIB',
                      ),
                      isThreeLine: true,
                      enabled: !r.instrumental,
                      onTap: () {
                        widget.controller.attachLyrics(
                          widget.track,
                          lines: parseLrc(r.synced),
                          plain: r.plain,
                          source: 'LRCLIB',
                          sourceUrl: r.sourceUrl,
                        );
                        Navigator.pop(context);
                      },
                    );
                  },
                );
              },
            ),
          ),
          if (_linkError != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Text(_linkError!),
            ),
          const Divider(),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: Wrap(
              spacing: 4,
              children: [
                TextButton.icon(
                  onPressed: _genius,
                  icon: const Icon(Icons.open_in_new, size: 17),
                  label: const Text('Consulta Genius'),
                ),
                TextButton.icon(
                  onPressed: () {
                    Navigator.pop(context);
                    widget.controller.importLyrics(widget.track);
                  },
                  icon: const Icon(Icons.upload_file_outlined, size: 17),
                  label: const Text('Importa LRC'),
                ),
                TextButton.icon(
                  onPressed: () async {
                    final text = await showDialog<String>(
                      context: context,
                      builder: (_) => const _PasteLyrics(),
                    );
                    if (text != null && text.trim().isNotEmpty) {
                      widget.controller.attachLyrics(
                        widget.track,
                        lines: parseLrc(text),
                        plain: text.trim(),
                        source: 'Testo personale',
                      );
                      if (context.mounted) Navigator.pop(context);
                    }
                  },
                  icon: const Icon(Icons.content_paste, size: 17),
                  label: const Text('Incolla testo'),
                ),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}

class _PasteLyrics extends StatefulWidget {
  const _PasteLyrics();
  @override
  State<_PasteLyrics> createState() => _PasteLyricsState();
}

class _PasteLyricsState extends State<_PasteLyrics> {
  final _text = TextEditingController();
  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: const Text('Importa un testo'),
    content: SizedBox(
      width: 400,
      child: TextField(
        controller: _text,
        maxLines: 10,
        maxLength: 50000,
        decoration: const InputDecoration(
          hintText: 'Incolla qui il testo o le righe LRC.',
        ),
      ),
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: const Text('Annulla'),
      ),
      TextButton(
        onPressed: () => Navigator.pop(context, _text.text),
        child: const Text('Importa'),
      ),
    ],
  );
}
