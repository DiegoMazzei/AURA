import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:aura/core/storage/library_store.dart';

void main() {
  test('atomic library writes survive a fresh store instance', () async {
    final root = await Directory.systemTemp.createTemp('aura-storage-');
    try {
      final store = DeviceLibraryStore(directory: () async => root);
      await store.write({
        'version': 1,
        'favorites': ['one'],
      });
      await store.write({
        'version': 1,
        'favorites': ['one', 'two'],
      });
      final restored = DeviceLibraryStore(directory: () async => root);
      expect((await restored.read())?['favorites'], ['one', 'two']);
      expect(await File('${root.path}/library.pending.json').exists(), isFalse);
    } finally {
      await root.delete(recursive: true);
    }
  });
  test('corrupt library is backed up before an error is reported', () async {
    final root = await Directory.systemTemp.createTemp('aura-corrupt-');
    try {
      final file = File('${root.path}/library.json');
      await file.writeAsString('{ broken');
      final store = DeviceLibraryStore(directory: () async => root);
      await expectLater(store.read(), throwsFormatException);
      final backups = await root
          .list()
          .where((f) => f.path.contains('.backup-'))
          .toList();
      expect(backups.length, 1);
      expect(await File(backups.first.path).readAsString(), '{ broken');
    } finally {
      await root.delete(recursive: true);
    }
  });
}
