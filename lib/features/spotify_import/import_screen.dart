import 'package:flutter/material.dart';

import '../youtube/online_search_screen.dart';

import '../../app/aura_controller.dart';
import '../../core/design/aura_design.dart';
import 'metadata_import.dart';

class ImportScreen extends StatefulWidget {
  const ImportScreen({super.key, required this.controller});
  final AuraController controller;
  @override
  State<ImportScreen> createState() => _ImportScreenState();
}

class _ImportScreenState extends State<ImportScreen> {
  String _query = '';
  Future<void> _search(ImportedSong song) async {
    await Navigator.push(
      context,
      MaterialPageRoute<void>(
        builder: (ctx) => Scaffold(
          appBar: AppBar(title: const Text('Trova su YouTube')),
          body: AuraBackground(
            child: OnlineSearchScreen(
              controller: widget.controller,
              initialQuery: '${song.title} ${song.artist}',
              showLocalLink: false,
              onLocal: () => Navigator.pop(ctx),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: widget.controller,
    builder: (_, _) {
      final c = widget.controller;
      return Scaffold(
        appBar: AppBar(title: const Text('Porta il tuo universo')),
        body: AuraBackground(
          color: auraViolet,
          child: ListView(
            padding: const EdgeInsets.all(24),
            children: [
              const Text(
                'Spotify → AURA',
                style: TextStyle(
                  fontSize: 30,
                  fontWeight: FontWeight.w600,
                  letterSpacing: -1,
                ),
              ),
              const SizedBox(height: 14),
              Text(
                'Ritrova le tue playlist importando un’esportazione JSON o CSV. Importiamo nomi, artisti e album; i file audio non sono inclusi.',
                style: TextStyle(color: context.muted, height: 1.6),
              ),
              const SizedBox(height: 20),
              FilledButton.icon(
                onPressed: c.importing
                    ? null
                    : () async {
                        final count = await c.importMusicMetadata();
                        if (context.mounted && count != null) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('$count nuove raccolte importate'),
                            ),
                          );
                        }
                      },
                icon: const Icon(Icons.file_upload_outlined),
                label: Text(
                  c.importing ? 'Importazione…' : 'Importa JSON o CSV',
                ),
              ),
              if (c.importing) const LinearProgressIndicator(),
              if (c.error != null)
                Padding(
                  padding: const EdgeInsets.only(top: 16),
                  child: Text(
                    c.error!,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                ),
              const SizedBox(height: 16),
              Text(
                'Collegamento diretto Spotify non ancora configurato. Cerca ogni brano su YouTube dentro AURA e scegli il risultato corretto. Nessuna corrispondenza viene scelta automaticamente.',
                style: TextStyle(
                  color: context.muted,
                  fontSize: 12,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 24),
              TextField(
                onChanged: (v) =>
                    setState(() => _query = v.toLowerCase().trim()),
                decoration: const InputDecoration(
                  hintText: 'Cerca nelle raccolte importate',
                  prefixIcon: Icon(Icons.search),
                ),
              ),
              if (c.importedCollections.isEmpty)
                const EmptyMessage(
                  icon: Icons.auto_awesome_outlined,
                  title: 'La tua storia musicale, qui',
                  message: 'Scegli un file esportato per iniziare. Non serve inserire la password Spotify.',
                ),
              ...c.importedCollections.map((collection) {
                final songs = collection.songs
                    .where(
                      (s) => '${s.title} ${s.artist} ${collection.name}'
                          .toLowerCase()
                          .contains(_query),
                    )
                    .toList();
                if (songs.isEmpty) return const SizedBox.shrink();
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SectionTitle('${collection.name} · ${songs.length}'),
                    ...songs.map(
                      (s) => ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: const Icon(Icons.music_note_outlined),
                        title: Text(s.title),
                        subtitle: Text('${s.artist}\nCerca su YouTube in AURA'),
                        isThreeLine: true,
                        trailing: const Icon(
                          Icons.open_in_new_rounded,
                          size: 18,
                        ),
                        onTap: () => _search(s),
                      ),
                    ),
                  ],
                );
              }),
            ],
          ),
        ),
      );
    },
  );
}
