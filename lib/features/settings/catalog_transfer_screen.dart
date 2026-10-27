import 'dart:io';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../app/aura_controller.dart';
import '../../core/design/aura_design.dart';
import '../../core/storage/catalog_backup.dart';
import '../../core/storage/library_store.dart';

Future<Uint8List> _encodeBackup(Map<String, dynamic> input) =>
    CatalogBackup.create(
      Map<String, dynamic>.from(input['catalog'] as Map),
      Directory(input['root'] as String),
    );

class CatalogTransferScreen extends StatefulWidget {
  const CatalogTransferScreen({super.key, required this.controller});
  final AuraController controller;
  @override
  State<CatalogTransferScreen> createState() => _CatalogTransferScreenState();
}

class _CatalogTransferScreenState extends State<CatalogTransferScreen> {
  bool _busy = false;
  String? _message;
  Future<void> _run(Future<String?> Function() action) async {
    setState(() {
      _busy = true;
      _message = null;
    });
    try {
      final message = await action();
      if (mounted) setState(() => _message = message);
    } catch (error) {
      if (mounted) {
        setState(
          () => _message = error is FormatException ? error.message.toString() : 'Operazione non riuscita. Controlla il file e lo spazio disponibile, poi riprova.',
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<String?> _export() async {
    final c = widget.controller;
    if (c.store is! DeviceLibraryStore) {
      throw StateError('Device library required');
    }
    final root = await (c.store as DeviceLibraryStore).libraryDirectory();
    final bytes = await compute(_encodeBackup, {
      'catalog': c.snapshot(),
      'root': root.path,
    });
    final uri = await FilePicker.saveFile(
      fileName:
          'AURA-catalogo-${DateTime.now().toIso8601String().substring(0, 10)}.zip',
      bytes: bytes,
      mimeType: 'application/zip',
      dialogTitle: 'Salva il tuo catalogo AURA',
    );
    return uri == null
        ? null
        : 'Catalogo esportato. Trasferisci il file sul nuovo telefono e scegli Importa catalogo.';
  }

  Future<String?> _import() async {
    final picked = await FilePicker.pickFile(
      type: FileType.custom,
      allowedExtensions: ['zip'],
    );
    if (picked == null) return null;
    final length = await picked.length();
    if (length != null && length > catalogBackupLimit) {
      throw const FormatException('Il backup supera 100 MB.');
    }
    final builder = BytesBuilder(copy: false);
    await for (final chunk in picked.readAsByteStream()) {
      if (builder.length + chunk.length > catalogBackupLimit) {
        throw const FormatException('Il backup supera 100 MB.');
      }
      builder.add(chunk);
    }
    final backup = await compute(CatalogBackup.decode, builder.takeBytes());
    await widget.controller.importCatalogBackup(backup);
    return 'Catalogo importato. Preferiti, artisti, playlist e file locali sono disponibili nella libreria.';
  }

  @override
  Widget build(BuildContext context) => PopScope(
    canPop: !_busy,
    child: Scaffold(
      appBar: AppBar(
        title: const Text('Trasferisci il catalogo'),
        automaticallyImplyLeading: !_busy,
      ),
      body: AuraBackground(
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            const Icon(Icons.library_music_outlined, size: 48),
            const SizedBox(height: 24),
            const Text(
              'La tua musica, anche sul prossimo telefono.',
              style: TextStyle(fontSize: 28, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 16),
            Text(
              'Esporta un file ZIP, salvalo in File o Drive e trasferiscilo sul nuovo dispositivo. Funziona tra iPhone e Android.',
              style: TextStyle(color: context.muted, height: 1.6),
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: _busy ? null : () => _run(_export),
              icon: const Icon(Icons.upload_file),
              label: const Text('Esporta catalogo'),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: _busy ? null : () => _run(_import),
              icon: const Icon(Icons.download_outlined),
              label: const Text('Importa catalogo'),
            ),
            if (_busy)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 24),
                child: LinearProgressIndicator(),
              ),
            if (_message != null)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 20),
                child: Text(_message!, semanticsLabel: _message),
              ),
            const SizedBox(height: 24),
            const SectionTitle('Cosa viene trasferito'),
            Text(
              'Brani salvati, preferiti, artisti seguiti, playlist, raccolte importate e cronologia. Include i file audio locali, fino a 100 MB complessivi. I brani online rimangono collegamenti: non vengono scaricati. Foto e copertine vengono ricaricate dai provider.',
              style: TextStyle(color: context.muted, height: 1.6),
            ),
            const SizedBox(height: 18),
            Text(
              'L’importazione aggiunge i contenuti senza cancellare la libreria esistente. Su una libreria nuova ripristina anche nome, tema e colore. Il file contiene i tuoi dati: conservalo in un luogo privato.',
              style: TextStyle(color: context.muted, height: 1.6),
            ),
          ],
        ),
      ),
    ),
  );
}
