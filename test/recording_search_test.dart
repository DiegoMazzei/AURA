import 'package:flutter_test/flutter_test.dart';
import 'package:aura/core/catalog/catalog_identity.dart';
import 'package:aura/core/catalog/recording_search.dart';
import 'package:aura/features/youtube/online_track.dart';
import 'package:aura/shared/models/music.dart';

import 'fakes.dart';

const bu = Track(
  id: 'catalog:bu',
  title: 'BU!',
  artist: 'Ernia',
  album: 'PER SOLDI E PER AMORE',
  source: '',
  durationSeconds: 205,
  catalogIdentity: CatalogIdentity(
    recordingId: 'bu',
    title: 'BU!',
    artists: [CatalogArtist(id: 'ernia', name: 'Ernia')],
  ),
);
const visual = OnlineTrack(
  id: '_eSCaOsaboc',
  title: 'Ernia - BU! (Visual)',
  artist: 'Ernia',
  durationSeconds: 205,
);
void main() {
  final cases = [
    (
      'Travis Scott',
      'FE!N (feat. Playboi Carti)',
      'Travis Scott - FE!N (Official Music Video) ft. Playboi Carti',
      'TravisScottVEVO',
      194,
      199,
    ),
    (
      'Dua Lipa',
      "Don't Start Now",
      'Dua Lipa – Don’t Start Now (Official Music Video)',
      'Dua Lipa',
      183,
      198,
    ),
    (
      'The Weeknd',
      'Blinding Lights',
      'Blinding Lights (Official Audio)',
      'TheWeekndVEVO',
      200,
      200,
    ),
    ('Adele', 'Hello', 'Adele:Hello [Lyrics]', 'Label', 295, 296),
    (
      'Gemitaiz',
      'Senza di me (feat. Venerus & Franco126)',
      'Gemitaiz - Senza di me ft. Venerus & Franco126',
      'GemitaizVEVO',
      194,
      195,
    ),
    ('a-ha', 'Take On Me', 'a-ha-Take On Me (Video)', 'a-ha', 225, 229),
  ];
  for (final c in cases) {
    test('general automatic recognition: ${c.$1} / ${c.$2}', () {
      final seed = Track(
        id: 'seed',
        title: c.$2,
        artist: c.$1,
        source: '',
        durationSeconds: c.$5,
        catalogIdentity: CatalogIdentity(
          recordingId: 'recording',
          title: c.$2,
          artists: [CatalogArtist(id: 'artist', name: c.$1)],
        ),
      );
      expect(
        matchesRecording(
          seed,
          OnlineTrack(
            id: 'source',
            title: c.$3,
            artist: c.$4,
            durationSeconds: c.$6,
          ),
        ),
        isTrue,
      );
    });
  }

  test('real Ernia BU Visual result is recognized and ranked before unrelated songs', () async {
    final c = FakeMusicCatalog()
      ..results = const [
        OnlineTrack(
          id: 'bugie',
          title: 'Ernia - Bugie (Visual)',
          artist: 'Ernia',
          durationSeconds: 204,
        ),
        visual,
      ];
    final found = await findRecordings(c, bu);
    expect(found.first.id, visual.id);
    expect(matchesRecording(bu, visual), isTrue);
    expect(c.requests, ['Ernia BU!']);
  });
  test('unrelated or different musical versions never auto match', () async {
    const other = OnlineTrack(
      id: 'other',
      title: 'Ernia - BU! (Live)',
      artist: 'Ernia',
      durationSeconds: 205,
    );
    final c = FakeMusicCatalog()..results = const [other];
    expect(await findRecordings(c, bu), [other]);
    expect(matchesRecording(bu, other), isFalse);
    expect(
      matchesRecording(
        bu,
        const OnlineTrack(
          id: 'x',
          title: 'BU! (Visual)',
          artist: 'Altro artista',
          durationSeconds: 205,
        ),
      ),
      isFalse,
    );
    expect(
      matchesRecording(
        bu,
        const OnlineTrack(
          id: 'x',
          title: 'Ernia - BU! (Remix)',
          artist: 'Ernia',
          durationSeconds: 205,
        ),
      ),
      isFalse,
    );
  });
}
