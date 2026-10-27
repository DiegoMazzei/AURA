import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../app/aura_controller.dart';
import '../../core/design/aura_design.dart';
import 'spotify_connection.dart';

class SpotifyConnectScreen extends StatefulWidget {
  const SpotifyConnectScreen({super.key, required this.controller});
  final AuraController controller;
  @override
  State<SpotifyConnectScreen> createState() => _SpotifyConnectState();
}

class _SpotifyConnectState extends State<SpotifyConnectScreen> {
  late final field = TextEditingController(
    text: widget.controller.spotifyClientId,
  );
  bool busy = false;
  String? status;
  @override
  void dispose() {
    field.dispose();
    super.dispose();
  }

  Future<void> connect() async {
    widget.controller.setSpotifyClientId(field.text);
    setState(() {
      busy = true;
      status = 'Apro Spotify…';
    });
    try {
      final result = await SpotifyConnection().connectAndImport(
        field.text.trim(),
        onProgress: (v) {
          if (mounted) setState(() => status = v);
        },
      );
      await widget.controller.importSpotifyCollections(result.collections);
      if (mounted) {
        setState(
          () => status =
              'Importate ${result.collections.length} raccolte.${result.skipped.isEmpty ? '' : ' ${result.skipped.length} playlist non accessibili con i permessi Spotify attuali.'}',
        );
      }
    } catch (e) {
      if (mounted) {
        setState(
          () => status = e is FormatException ? e.message : 'Importazione non completata. Verifica configurazione e autorizzazione Spotify.',
        );
      }
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Spotify')),
    body: ListView(
      padding: const EdgeInsets.all(24),
      children: [
        const Text(
          'La tua musica, in AURA',
          style: TextStyle(fontSize: 30, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 16),
        Text(
          'Accedi a Spotify per importare brani preferiti e playlist accessibili. Non modifichiamo il tuo account. L’audio continua a usare il player di AURA.',
          style: TextStyle(color: context.muted, height: 1.5),
        ),
        const SizedBox(height: 24),
        TextField(
          controller: field,
          enabled: !busy,
          autocorrect: false,
          decoration: const InputDecoration(
            labelText: 'Client ID Spotify',
            hintText: 'Configurazione iniziale',
          ),
        ),
        const SizedBox(height: 16),
        FilledButton.icon(
          onPressed: busy ? null : connect,
          icon: busy
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.link),
          label: const Text('Collega e importa'),
        ),
        if (status != null)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 18),
            child: Text(status!),
          ),
        ExpansionTile(
          title: const Text('Prima configurazione'),
          children: [
            const Text(
              'Crea un’app nel pannello Spotify Developer, abilita Web API e aggiungi questo indirizzo di ritorno. Copia poi il Client ID nel campo sopra. Il Client Secret non serve.',
            ),
            const SizedBox(height: 12),
            const SelectableText(spotifyRedirect),
            const SizedBox(height: 12),
            TextButton(
              onPressed: () => launchUrl(
                Uri.parse('https://developer.spotify.com/dashboard'),
                mode: LaunchMode.externalApplication,
              ),
              child: const Text('Apri Spotify Developer'),
            ),
            const Text(
              'In modalità sviluppo Spotify richiede un account Premium per il proprietario dell’app. Alcune playlist di altri utenti possono non essere accessibili.',
            ),
          ],
        ),
        const SizedBox(height: 24),
        Text(
          'Le credenziali rimangono con Spotify. Il token serve solo per questa importazione e non viene salvato. Il Client ID viene conservato sul dispositivo.',
          style: TextStyle(color: context.muted, fontSize: 12, height: 1.4),
        ),
      ],
    ),
  );
}
