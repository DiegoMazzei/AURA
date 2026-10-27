import 'package:flutter/material.dart';

import '../../app/aura_controller.dart';
import '../../shared/models/music.dart';
import '../../core/catalog/musicbrainz_catalog.dart';
import '../../core/design/aura_design.dart';

Future<void> chooseCatalogMatch(
  BuildContext context,
  AuraController c,
  Track t,
) => showModalBottomSheet<void>(
  context: context,
  isScrollControlled: true,
  builder: (_) => _CatalogMatches(controller: c, track: t),
);

class _CatalogMatches extends StatefulWidget {
  const _CatalogMatches({required this.controller, required this.track});
  final AuraController controller;
  final Track track;
  @override
  State<_CatalogMatches> createState() => _CatalogMatchesState();
}

class _CatalogMatchesState extends State<_CatalogMatches> {
  late Future<List<CatalogMatch>> _results = _search();
  Future<List<CatalogMatch>> _search() async =>
      await widget.controller.metadataCatalog?.search(widget.track) ?? [];
  @override
  Widget build(BuildContext context) => SafeArea(
    child: SizedBox(
      height: MediaQuery.sizeOf(context).height * .72,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 24, 16, 8),
            child: Row(
              children: [
                const Expanded(
                  child: Text(
                    'Artista e album',
                    style: TextStyle(fontSize: 26, fontWeight: FontWeight.w700),
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
              'Scegli la registrazione corretta.',
              style: TextStyle(color: context.muted),
            ),
          ),
          const SizedBox(height: 14),
          Expanded(
            child: FutureBuilder<List<CatalogMatch>>(
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
                        const Text('Il catalogo non è disponibile.'),
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
                    child: Text(
                      'Nessuna corrispondenza. Puoi modificare i dati a mano.',
                    ),
                  );
                }
                return ListView.builder(
                  itemCount: results.length,
                  itemBuilder: (context, i) {
                    final m = results[i];
                    return ListTile(
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 6,
                      ),
                      leading: CosmicCover(
                        size: 52,
                        radius: 8,
                        imageUrl: m.identity.artworkUrl,
                      ),
                      title: Text(m.identity.title),
                      subtitle: Text(
                        '${m.artist}\n${m.identity.album.isEmpty ? 'Album non disponibile' : m.identity.album} · ${m.identity.provider}',
                      ),
                      isThreeLine: true,
                      trailing: const Icon(Icons.add_circle_outline),
                      onTap: () {
                        widget.controller.applyCatalogIdentity(
                          widget.track,
                          m.identity,
                        );
                        Navigator.pop(context);
                      },
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    ),
  );
}
