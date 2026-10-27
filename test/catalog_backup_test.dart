import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:aura/app/aura_controller.dart';
import 'package:aura/core/storage/catalog_backup.dart';
import 'package:aura/core/storage/library_store.dart';
import 'package:aura/core/catalog/artist_directory.dart';
import 'package:aura/shared/models/music.dart';
import 'package:flutter_test/flutter_test.dart';

import 'fakes.dart';

const song = Track(
  id: 'yt:abcdefghijk',
  title: 'Brano',
  artist: 'Artista',
  source: 'abcdefghijk',
  isYoutube: true,
);
Map<String, dynamic> catalog() => {
  'version': 1,
  'tracks': [song.toJson()],
  'favorites': [song.id],
  'favoriteArtists': [const DirectoryArtist(id: 8, name: 'Artista').toJson()],
  'playlists': [
    AuraPlaylist(id: 'p', name: 'Preferite', trackIds: [song.id]).toJson(),
  ],
  'recent': [song.id],
  'displayName': 'Nome',
  'theme': 'dark',
  'accentColor': 0xff008b8b,
};

void main() {
  late Directory root;
  setUp(() async {
    root = await Directory.systemTemp.createTemp('aura-transfer-test-');
  });
  tearDown(() async {
    await root.delete(recursive: true);
  });

  test(
    'backup moves online catalog and preferences without client configuration',
    () async {
      final source = catalog()
        ..['spotifyClientId'] = 'private-device-setting'
        ..['artworkCache'] = {'path': '/old/device/cache'};
      final bytes = await CatalogBackup.create(source, root);
      final backup = CatalogBackup.decode(bytes);
      expect(backup.catalog['spotifyClientId'], isNull);
      expect(backup.catalog['artworkCache'], isNull);
      final c = AuraController(
        audio: FakeAudioEngine(),
        store: MemoryLibraryStore(),
      );
      await c.initialize();
      await c.importCatalogBackup(backup);
      expect(c.favorites, {song.id});
      expect(c.favoriteArtists[8]?.name, 'Artista');
      expect(c.playlists.single.trackIds, [song.id]);
      expect(c.displayName, 'Nome');
      expect(c.accentColor, 0xff008b8b);
      expect(c.audio.playing, isFalse);
      final restored = AuraController(audio: FakeAudioEngine(), store: c.store);
      await restored.initialize();
      expect(restored.favorites, {song.id});
      expect(restored.playlists.single.name, 'Preferite');
      c.dispose();
      restored.dispose();
    },
  );

  test(
    'local audio is packaged and installed under a portable verified path',
    () async {
      await Directory('${root.path}/audio').create();
      final audio = Uint8List.fromList(List.generate(2048, (i) => i % 256));
      await File('${root.path}/audio/local.wav').writeAsBytes(audio);
      final source = catalog()
        ..['tracks'] = [
          const Track(
            id: 'local',
            title: 'Locale',
            artist: 'Nome',
            source: 'audio/local.wav',
          ).toJson(),
        ]
        ..['favorites'] = ['local']
        ..['playlists'] = [];
      final backup = CatalogBackup.decode(
        await CatalogBackup.create(source, root),
      );
      final other = await Directory('${root.path}/new-phone').create();
      final store = DeviceLibraryStore(directory: () async => other);
      final c = AuraController(audio: FakeAudioEngine(), store: store);
      await c.initialize();
      await c.importCatalogBackup(backup);
      final track = c.tracks.single;
      expect(track.source, startsWith('audio/restore-'));
      expect(await File('${other.path}/${track.source}').readAsBytes(), audio);
      await c.importCatalogBackup(backup);
      expect(c.tracks.length, 1);
      expect(
        (await Directory('${other.path}/audio').list().toList()).length,
        1,
      );
      final again = CatalogBackup.decode(
        await CatalogBackup.create(c.snapshot(), other),
      );
      expect(again.audio.values.single, audio);
      c.dispose();
    },
  );

  test(
    'merge is repeatable and keeps existing library, profile and metadata',
    () {
      final old = catalog()..['displayName'] = 'Esistente';
      final backup = CatalogBackup(catalog(), {});
      final once = mergeCatalog(old, backup);
      final twice = mergeCatalog(once, backup);
      expect(twice, once);
      expect(twice['displayName'], 'Esistente');
      expect(twice['tracks'], hasLength(1));
      expect(twice['playlists'], hasLength(1));
    },
  );

  test(
    'track ID collisions remap favorites and playlists instead of overwriting',
    () {
      final incoming = catalog();
      final t =
          Map<String, dynamic>.from((incoming['tracks'] as List).single as Map)
            ..['source'] = 'ABCDEFGHIJK'
            ..['title'] = 'Altro';
      incoming['tracks'] = [t];
      final result = mergeCatalog(catalog(), CatalogBackup(incoming, {}));
      expect(result['tracks'], hasLength(2));
      final id = ((result['tracks'] as List).last as Map)['id'];
      expect(id, startsWith('restore:'));
      expect(result['favorites'], containsAll([song.id, id]));
      expect(
        ((result['playlists'] as List).single as Map)['trackIds'],
        containsAll([song.id, id]),
      );
    },
  );

  test('failed persistence leaves the receiving catalog unchanged', () async {
    final store = MemoryLibraryStore()..failWrite = true;
    final c = AuraController(audio: FakeAudioEngine(), store: store);
    await c.initialize();
    await expectLater(
      c.importCatalogBackup(CatalogBackup(catalog(), {})),
      throwsStateError,
    );
    expect(c.tracks, isEmpty);
    expect(c.favorites, isEmpty);
    c.dispose();
  });

  test(
    'rejects traversal, unknown schemas, missing audio and malformed data',
    () {
      final traversal = Archive()
        ..addFile(ArchiveFile.string('../escape', 'no'));
      expect(
        () => CatalogBackup.decode(
          Uint8List.fromList(ZipEncoder().encode(traversal)),
        ),
        throwsFormatException,
      );
      final future = Archive()
        ..addFile(
          ArchiveFile.string(
            'catalog.json',
            jsonEncode({
              'format': 'aura-catalog',
              'schema': 99,
              'catalog': catalog(),
              'files': {},
            }),
          ),
        );
      expect(
        () => CatalogBackup.decode(
          Uint8List.fromList(ZipEncoder().encode(future)),
        ),
        throwsFormatException,
      );
      final missing = catalog()
        ..['tracks'] = [
          const Track(
            id: 'local',
            title: 'A',
            artist: 'B',
            source: 'audio/missing.mp3',
          ).toJson(),
        ];
      final zip = Archive()
        ..addFile(
          ArchiveFile.string(
            'catalog.json',
            jsonEncode({
              'format': 'aura-catalog',
              'schema': 1,
              'catalog': missing,
              'files': {},
            }),
          ),
        );
      expect(
        () =>
            CatalogBackup.decode(Uint8List.fromList(ZipEncoder().encode(zip))),
        throwsFormatException,
      );
      expect(
        () => CatalogBackup.decode(Uint8List.fromList([1, 2, 3])),
        throwsFormatException,
      );
    },
  );

  test('export reports missing local media rather than creating incomplete backups', () async {
    final source = catalog()
      ..['tracks'] = [
        const Track(
          id: 'local',
          title: 'A',
          artist: 'B',
          source: 'audio/missing.mp3',
        ).toJson(),
      ];
    await expectLater(
      CatalogBackup.create(source, root),
      throwsFormatException,
    );
  });
}
