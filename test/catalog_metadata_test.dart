import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:aura/app/aura_controller.dart';
import 'package:aura/core/catalog/catalog_identity.dart';
import 'package:aura/core/catalog/musicbrainz_catalog.dart';
import 'package:aura/core/lyrics/lyrics_provider.dart';
import 'package:aura/features/library/library_groups.dart';
import 'package:aura/shared/models/music.dart';

import 'fakes.dart';

const artist = CatalogArtist(id: 'artist-1', name: 'Artista');
const guest = CatalogArtist(id: 'artist-2', name: 'Ospite');
const identity = CatalogIdentity(
  recordingId: 'recording-1',
  title: 'Una luce',
  artists: [artist, guest],
  releaseId: 'release-1',
  releaseGroupId: 'album-1',
  album: 'Orizzonti',
  albumArtistId: 'artist-1',
  albumArtist: 'Artista',
);
const song = Track(
  id: 'song',
  title: 'Una luce',
  artist: 'Artista',
  source: 'sample',
  durationSeconds: 180,
);

class _Catalog implements MetadataCatalog {
  final pending = Completer<List<CatalogMatch>>();
  @override
  Future<List<CatalogMatch>> search(Track track) => pending.future;
}

void main() {
  test(
    'canonical artist IDs merge aliases and featured artists are discoverable',
    () {
      final a = song.copyWith(catalogIdentity: identity);
      final b = song.copyWith(
        artist: 'Alias',
        catalogIdentity: const CatalogIdentity(
          recordingId: 'r2',
          title: 'Altro brano',
          artists: [CatalogArtist(id: 'artist-1', name: 'Artista')],
          releaseGroupId: 'album-1',
          album: 'Orizzonti',
          albumArtist: 'Artista',
        ),
      );
      final groups = groupByArtist([a, b]);
      expect(groups.length, 2);
      expect(groups.firstWhere((g) => g.name == 'Artista').tracks.length, 2);
      expect(groups.firstWhere((g) => g.name == 'Ospite').tracks.length, 1);
      expect(groupByAlbum([a, b]).single.tracks.length, 2);
    },
  );
  test(
    'catalog identity and sourced synchronized/plain lyrics survive JSON',
    () {
      final original = song.copyWith(
        catalogIdentity: identity,
        lyrics: const [LyricLine(Duration(seconds: 2), 'Una luce inventata')],
        plainLyrics: 'Una luce inventata',
        lyricsSource: 'Fixture',
        lyricsSourceUrl: 'https://example.org/lyrics',
      );
      final restored = Track.fromJson(original.toJson());
      expect(restored.catalogIdentity!.artists.last.id, 'artist-2');
      expect(restored.catalogIdentity!.releaseGroupId, 'album-1');
      expect(restored.plainLyrics, 'Una luce inventata');
      expect(restored.lyrics.single.at.inSeconds, 2);
      expect(restored.lyricsSourceUrl, 'https://example.org/lyrics');
      final old = Track.fromJson(
        song.toJson()
          ..remove('catalogIdentity')
          ..remove('plainLyrics'),
      );
      expect(old.catalogIdentity, isNull);
      expect(old.plainLyrics, isEmpty);
    },
  );
  test(
    'automatic matching keeps live/remix editions and duration distinct',
    () {
      const match = CatalogMatch(identity, score: 100, durationSeconds: 180);
      expect(isConfidentCatalogMatch(song, match), isTrue);
      expect(
        isConfidentCatalogMatch(
          song.copyWith(title: 'Artista - Una luce (Official Audio)'),
          match,
        ),
        isTrue,
      );
      expect(
        isConfidentCatalogMatch(song.copyWith(title: 'Una luce (Live)'), match),
        isFalse,
      );
      expect(
        isConfidentCatalogMatch(song.copyWith(durationSeconds: 240), match),
        isFalse,
      );
      expect(normalizeMusicText('東京の音楽'), isNotEmpty);
    },
  );
  test(
    'MusicBrainz selects original studio album over a compilation and a single',
    () {
      final results = parseMusicBrainzRecordings({
        'recordings': [
          {
            'id': 'r',
            'title': 'Una luce',
            'score': 100,
            'length': 180000,
            'artist-credit': [
              {
                'artist': {'id': 'artist-1', 'name': 'Artista'},
              },
            ],
            'releases': [
              {
                'id': 'compilation',
                'title': 'Raccolta',
                'status': 'Official',
                'date': '1990',
                'release-group': {
                  'id': 'c',
                  'primary-type': 'Album',
                  'secondary-types': ['Compilation'],
                },
              },
              {
                'id': 'single',
                'title': 'Singolo',
                'status': 'Official',
                'date': '1999',
                'release-group': {'id': 's', 'primary-type': 'Single'},
              },
              {
                'id': 'original',
                'title': 'Orizzonti',
                'status': 'Official',
                'date': '2000',
                'release-group': {'id': 'a', 'primary-type': 'Album'},
              },
            ],
          },
        ],
      });
      expect(results.single.identity.releaseId, 'original');
      expect(results.single.identity.album, 'Orizzonti');
    },
  );
  test('catalog association never blocks playback and preserves edits made during lookup', () async {
    final provider = _Catalog();
    final audio = FakeAudioEngine();
    final store = MemoryLibraryStore()..imported = [song];
    final c = AuraController(
      includeDemoTracks: true,
      audio: audio,
      store: store,
      metadataCatalog: provider,
    );
    await c.initialize();
    await c.importAudio();
    await c.playTrack(song);
    expect(audio.playing, isTrue);
    expect(c.busy, isFalse);
    c.updateTrackMetadata(
      song,
      title: 'Scelta personale',
      artist: 'Io',
      album: 'Mio album',
    );
    provider.pending.complete([
      const CatalogMatch(identity, score: 100, durationSeconds: 180),
    ]);
    await Future<void>.delayed(Duration.zero);
    expect(c.track(song.id)!.title, 'Scelta personale');
    expect(c.track(song.id)!.catalogIdentity, isNull);
    c.dispose();
  });
  test(
    'plain lyrics remain unsynchronized and instrumental records are explicit',
    () {
      final records = parseLyricsCandidates([
        {
          'id': 1,
          'trackName': 'Uno',
          'artistName': 'Artista',
          'plainLyrics': 'Riga originale inventata',
        },
        {
          'id': 2,
          'trackName': 'Due',
          'artistName': 'Artista',
          'syncedLyrics': '[00:02.00]Una riga inventata',
        },
        {
          'id': 3,
          'trackName': 'Tre',
          'artistName': 'Artista',
          'instrumental': true,
        },
        {'id': 4, 'trackName': 'Vuoto', 'artistName': 'Artista'},
      ]);
      expect(records.length, 3);
      expect(records[0].synchronized, isFalse);
      expect(records[1].synchronized, isTrue);
      expect(records[2].instrumental, isTrue);
    },
  );
}
