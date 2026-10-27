import '../../features/youtube/online_track.dart';
import '../../features/youtube/youtube_catalog.dart';
import '../../shared/models/music.dart';
import 'musicbrainz_catalog.dart';

String _recordingTitle(String value) => cleanMusicTitle(value)
    .replaceAll(
      RegExp(
        r'[\[(](?:feat\.?|ft\.?|featuring)\s+[^\])]+[\])]',
        caseSensitive: false,
      ),
      '',
    )
    .replaceAll(
      RegExp(r'[\[(](?:audio|music video)[\])]', caseSensitive: false),
      '',
    )
    .trim();

/// Only alternate uploads of the same credited recording may play unattended.
/// Live/remix/cover/version words remain significant; duration must agree.
bool _sameCreditAndTitle(Track song, OnlineTrack candidate) {
  final identity = song.catalogIdentity;
  if (identity == null) return false;
  final artists = {
    ...identity.artists.map((a) => normalizeMusicText(a.name)),
    normalizeMusicText(song.artist),
  };
  var title = _recordingTitle(candidate.title);
  var credited = artists.contains(
    normalizeMusicText(cleanMusicArtist(candidate.artist)),
  );
  final split = title.split(RegExp(r'\s[-–—]\s'));
  if (split.length > 1 && artists.contains(normalizeMusicText(split.first))) {
    credited = true;
    title = split.skip(1).join(' - ');
  }
  if (!credited ||
      normalizeMusicText(title) !=
          normalizeMusicText(_recordingTitle(song.title))) {
    return false;
  }
  return true;
}

bool matchesRecording(Track song, OnlineTrack candidate) {
  return _sameCreditAndTitle(song, candidate) &&
      (song.durationSeconds <= 0 ||
          (candidate.durationSeconds > 0 &&
              (song.durationSeconds - candidate.durationSeconds).abs() <= 8));
}

/// Full credits often produce empty searches, especially for classical music.
/// Try progressively shorter factual queries; never hide the version choice
/// when title, performer or duration cannot be verified.
Future<List<OnlineTrack>> findRecordings(
  MusicCatalog catalog,
  Track song,
) async {
  final primary =
      song.catalogIdentity?.artists.firstOrNull?.name ?? song.artist;
  final title = _recordingTitle(song.title);
  final queries = <String>{
    '${song.artist} ${song.title}'.trim(),
    '$primary $title'.trim(),
    if (song.album.isNotEmpty) '$title ${song.album}'.trim(),
  };
  final results = <String, OnlineTrack>{};
  Object? failure;
  var succeeded = false;
  for (final query in queries) {
    try {
      final found = await catalog.search(query);
      succeeded = true;
      for (final value in found) {
        results[value.id] = value;
      }
      if (found.any((t) => matchesRecording(song, t))) break;
    } catch (e) {
      failure = e;
    }
  }
  if (!succeeded && failure != null) throw failure;
  final exact = results.values.where((t) => matchesRecording(song, t));
  return [
    ...exact,
    ...results.values.where(
      (t) => _sameCreditAndTitle(song, t) && !matchesRecording(song, t),
    ),
  ];
}
