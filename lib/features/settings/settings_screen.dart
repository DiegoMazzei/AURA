import 'package:flutter/material.dart';

import '../../app/aura_controller.dart';
import '../../core/design/aura_design.dart';
import '../spotify_import/import_screen.dart';
import '../spotify_import/spotify_connect_screen.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key, required this.controller});
  final AuraController controller;
  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: controller,
    builder: (_, _) => Scaffold(
      appBar: AppBar(title: const Text('Il tuo AURA')),
      body: AuraBackground(
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            const SectionTitle('Profilo'),
            ListTile(
              leading: const Icon(Icons.person_outline),
              title: Text(
                controller.displayName.isEmpty
                    ? 'Come ti chiami?'
                    : controller.displayName,
              ),
              subtitle: const Text('Il nome che AURA usa per salutarti'),
              trailing: const Icon(Icons.edit_outlined),
              onTap: () async {
                final field = TextEditingController(
                  text: controller.displayName,
                );
                final name = await showDialog<String>(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: const Text('Il tuo nome'),
                    content: TextField(
                      controller: field,
                      autofocus: true,
                      maxLength: 40,
                      textCapitalization: TextCapitalization.words,
                      decoration: const InputDecoration(labelText: 'Nome'),
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(ctx),
                        child: const Text('Annulla'),
                      ),
                      FilledButton(
                        onPressed: () => Navigator.pop(ctx, field.text),
                        child: const Text('Salva'),
                      ),
                    ],
                  ),
                );
                if (name != null) controller.setDisplayName(name);
              },
            ),
            const SectionTitle('Aspetto'),
            AuraGlassSurface(
              padding: const EdgeInsets.all(10),
              child: Column(
                children: [
                  for (final mode in ThemeMode.values)
                    ListTile(
                      leading: Icon(
                        [
                          Icons.brightness_auto_outlined,
                          Icons.light_mode_outlined,
                          Icons.dark_mode_outlined,
                        ][mode.index],
                      ),
                      title: Text(
                        ['Come il dispositivo', 'Chiaro', 'Scuro'][mode.index],
                      ),
                      trailing: controller.themeMode == mode
                          ? const Icon(Icons.check_rounded)
                          : null,
                      onTap: () => controller.setTheme(mode),
                    ),
                ],
              ),
            ),
            const SectionTitle('La tua musica'),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.file_upload_outlined),
              title: const Text('Importa file audio'),
              subtitle: const Text('MP3, M4A, AAC, WAV, FLAC, OGG'),
              onTap: controller.importing ? null : controller.importAudio,
            ),
            const SectionTitle('Connessioni'),
            ListTile(
              leading: const Icon(Icons.file_download_outlined),
              title: const Text('Importa playlist da JSON o CSV'),
              subtitle: const Text('Esportazioni Spotify e raccolte personali'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute<void>(
                  builder: (_) => ImportScreen(controller: controller),
                ),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.link),
              title: const Text('Collega Spotify'),
              subtitle: const Text('Importa playlist e brani preferiti'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute<void>(
                  builder: (_) => SpotifyConnectScreen(controller: controller),
                ),
              ),
            ),
            const SectionTitle('Catalogo e testi'),
            Text(
              'Artisti e album: MusicBrainz, con Apple come catalogo di riserva. Foto e copertine: TheAudioDB e Deezer, con cache sul dispositivo e miniature originali come riserva. Le associazioni ambigue si possono scegliere dal menu del brano.\n\nTesti sincronizzati: LRCLIB, quando disponibili. Genius si apre per la consultazione; puoi anche importare file LRC o incollare un tuo testo.',
              style: TextStyle(color: context.muted, height: 1.6),
            ),
            const SectionTitle('Privacy e accessibilità'),
            Text(
              'La libreria rimane sul dispositivo. AURA non usa analitica propria. Le ricerche comunicano con YouTube; la catalogazione invia titolo e artista a MusicBrainz o Apple, la ricerca dei testi a LRCLIB. Per le immagini vengono inviati nomi di artisti e album a TheAudioDB o Deezer. Genius si apre solo quando lo scegli. Le animazioni seguono il movimento ridotto del sistema.',
              style: TextStyle(color: context.muted, height: 1.6),
            ),
            const SizedBox(height: 30),
            const Center(
              child: Text(
                'AURA',
                style: TextStyle(
                  fontSize: 30,
                  fontWeight: FontWeight.w200,
                  letterSpacing: 3,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Center(
              child: Text(
                'Your Music. Your Universe.',
                style: TextStyle(color: context.muted, fontSize: 12),
              ),
            ),
            const SizedBox(height: 9),
            Center(
              child: Text(
                '0.5.1 · Sviluppo',
                style: TextStyle(color: context.muted, fontSize: 11),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
