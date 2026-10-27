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
  test('uncertain results remain available for explicit choice but never auto match', () async {
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
