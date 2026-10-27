import 'package:flutter/material.dart';

import '../../app/aura_controller.dart';
import '../../core/design/aura_design.dart';
import '../spotify_import/import_screen.dart';

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
            AuraGlassSurface(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Spotify → AURA',
                    style: TextStyle(fontSize: 23, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Playlist, artisti e brani salvati. L’importazione Spotify richiede una configurazione OAuth e la tua autorizzazione; non è ancora attiva.',
                    style: TextStyle(color: context.muted, height: 1.5),
                  ),
                  const SizedBox(height: 18),
                  const Text(
                    'YouTube',
                    style: TextStyle(fontSize: 19, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Il catalogo di ricerca e la riproduzione online utilizzano YouTube. La disponibilità dei contenuti dipende dal servizio.',
                    style: TextStyle(color: context.muted, height: 1.5),
                  ),
                ],
              ),
            ),
            const SectionTitle('Catalogo e testi'),
            Text(
              'Artisti e album: MusicBrainz, con Apple come catalogo di riserva. Copertine: Cover Art Archive e miniature della sorgente. Le associazioni ambigue si possono scegliere dal menu del brano.\n\nTesti sincronizzati: LRCLIB, quando disponibili. Genius si apre per la consultazione; puoi anche importare file LRC o incollare un tuo testo.',
              style: TextStyle(color: context.muted, height: 1.6),
            ),
            const SectionTitle('Privacy e accessibilità'),
            Text(
              'La libreria rimane sul dispositivo. AURA non usa analitica propria. Le ricerche comunicano con YouTube; la catalogazione invia titolo e artista a MusicBrainz o Apple, la ricerca dei testi a LRCLIB. Genius si apre solo quando lo scegli. Le animazioni seguono il movimento ridotto del sistema.',
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
                '0.2 · Sviluppo',
                style: TextStyle(color: context.muted, fontSize: 11),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
