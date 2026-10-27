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
            _AccentPicker(controller: controller),
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
                '0.6.0 · Anteprima',
                style: TextStyle(color: context.muted, fontSize: 11),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

class _AccentPicker extends StatelessWidget {
  const _AccentPicker({required this.controller});
  final AuraController controller;
  static const colors = <String, int>{
    'Viola': 0xff9750e8,
    'Blu': 0xff2876dd,
    'Turchese': 0xff008b8b,
    'Verde': 0xff29834b,
    'Rosa': 0xffc63e85,
    'Corallo': 0xffc64c40,
    'Ambra': 0xffa86b09,
    'Grafite': 0xff646474,
  };
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: 24),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Il tuo colore',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        Text(
          'Cambia accenti, controlli e atmosfera dell’app.',
          style: TextStyle(color: context.muted),
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            for (final entry in colors.entries)
              Semantics(
                selected: controller.accentColor == entry.value,
                child: Tooltip(
                  message: entry.key,
                  child: InkWell(
                    customBorder: const CircleBorder(),
                    onTap: () => controller.setAccentColor(entry.value),
                    child: Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: Color(entry.value),
                        shape: BoxShape.circle,
                      ),
                      child: controller.accentColor == entry.value
                          ? const Icon(Icons.check_rounded, color: Colors.white)
                          : null,
                    ),
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 12),
        OutlinedButton.icon(
          icon: const Icon(Icons.palette_outlined),
          label: const Text('Colore personalizzato'),
          onPressed: () async {
            final color = await showDialog<int>(
              context: context,
              builder: (_) =>
                  _CustomColorDialog(initial: controller.accentColor),
            );
            if (color != null) controller.setAccentColor(color);
          },
        ),
      ],
    ),
  );
}

class _CustomColorDialog extends StatefulWidget {
  const _CustomColorDialog({required this.initial});
  final int initial;
  @override
  State<_CustomColorDialog> createState() => _CustomColorDialogState();
}

class _CustomColorDialogState extends State<_CustomColorDialog> {
  late final field = TextEditingController(
    text: (widget.initial & 0xffffff)
        .toRadixString(16)
        .padLeft(6, '0')
        .toUpperCase(),
  );
  String? error;
  @override
  void dispose() {
    field.dispose();
    super.dispose();
  }

  Color get _color {
    final value = field.text.trim().replaceFirst(RegExp(r'^#'), '');
    return Color(
      RegExp(r'^[a-fA-F0-9]{6}$').hasMatch(value)
          ? 0xff000000 | int.parse(value, radix: 16)
          : widget.initial,
    );
  }

  Widget _colorSlider(
    String label,
    double value,
    HSLColor Function(double) change,
  ) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(label, style: const TextStyle(fontSize: 12)),
      Slider(
        value: value,
        semanticFormatterCallback: (v) => '$label ${(v * 100).round()}%',
        onChanged: (v) => setState(() {
          field.text = (change(v).toColor().toARGB32() & 0xffffff)
              .toRadixString(16)
              .padLeft(6, '0')
              .toUpperCase();
          error = null;
        }),
      ),
    ],
  );
  @override
  Widget build(BuildContext context) => AlertDialog(
    title: const Text('Scegli il tuo colore'),
    content: SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            height: 52,
            width: double.infinity,
            decoration: BoxDecoration(
              color: _color,
              borderRadius: BorderRadius.circular(16),
            ),
          ),
          const SizedBox(height: 18),
          _colorSlider(
            'Tonalità',
            HSLColor.fromColor(_color).hue / 360,
            (v) => HSLColor.fromColor(_color).withHue(v * 360),
          ),
          _colorSlider(
            'Saturazione',
            HSLColor.fromColor(_color).saturation,
            (v) => HSLColor.fromColor(_color).withSaturation(v),
          ),
          _colorSlider(
            'Luminosità',
            HSLColor.fromColor(_color).lightness,
            (v) => HSLColor.fromColor(_color).withLightness(v),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: field,
            maxLength: 7,
            onChanged: (_) => setState(() => error = null),
            textCapitalization: TextCapitalization.characters,
            decoration: InputDecoration(
              labelText: 'Codice HEX',
              hintText: '#9750E8',
              errorText: error,
            ),
          ),
        ],
      ),
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: const Text('Annulla'),
      ),
      FilledButton(
        onPressed: () {
          final raw = field.text.trim().replaceFirst(RegExp(r'^#'), '');
          if (!RegExp(r'^[a-fA-F0-9]{6}$').hasMatch(raw)) {
            setState(() => error = 'Inserisci sei cifre, ad esempio 9750E8');
            return;
          }
          Navigator.pop(context, 0xff000000 | int.parse(raw, radix: 16));
        },
        child: const Text('Applica'),
      ),
    ],
  );
}
