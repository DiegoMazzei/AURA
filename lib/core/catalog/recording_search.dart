import 'dart:math' as math;

import '../../features/youtube/online_track.dart';
import '../../features/youtube/youtube_catalog.dart';
import '../../shared/models/music.dart';
import 'musicbrainz_catalog.dart';

String _text(String value) =>
    normalizeMusicText(value.replaceAll(RegExp("['’`´]"), ''));
const _presentation =
    r'(?:official(?:\s+(?:music|audio|video|lyric|lyrics|visual|visualizer|visualiser|hd|4k))*|audio(?:\s+ufficiale)?|music video|video(?:\s+ufficiale)?|videoclip|visual(?:\s+video)?|visuali[sz]er|lyric(?:s|\s+video)?|video lyrics|testo|hd|4k)';
String _recordingTitle(String value) => cleanMusicTitle(value)
    .replaceAll(
      RegExp(
        r'[\[(](?:feat\.?|ft\.?|featuring|prod\.?)\s+[^\])]+[\])]',
        caseSensitive: false,
      ),
      '',
    )
    .replaceAll(RegExp('[\\[(]$_presentation[\\])]', caseSensitive: false), '')
    .replaceAll(
      RegExp(
        '(?:\\s+[|–—-]\\s*|\\s+)$_presentation\\s*\$',
        caseSensitive: false,
      ),
      '',
    )
    .replaceAll(
      RegExp(r'\s+(?:feat\.?|ft\.?|featuring)\s+.+$', caseSensitive: false),
      '',
    )
    .replaceAll(RegExp(r'\s+[-–—|]+\s*$'), '')
    .trim();

String _artistKey(String value) =>
    _text(cleanMusicArtist(value)).replaceAll(' ', '');

Set<String> _versions(String title) => RegExp(
  r'\b(live|remix|acoustic|instrumental|karaoke|cover|sped\s*up|slowed|remaster(?:ed)?|radio\s+edit)\b',
  caseSensitive: false,
).allMatches(title).map((m) => _text(m[0]!)).toSet();

bool _sameVersions(String a, String b) {
  final first = _versions(a), second = _versions(b);
  return first.length == second.length && first.containsAll(second);
}

bool _credited(String value, Set<String> artists) {
  final normalized = _artistKey(value);
  if (artists.contains(normalized)) return true;
  return value
      .split(
        RegExp(r',\s*|\s+(?:&|x|and|feat\.?|ft\.?)\s+', caseSensitive: false),
      )
      .any((part) => artists.contains(_artistKey(part)));
}

/// General ranking for every artist. Presentation labels, punctuation and
/// featured credits are separate from the song title; musical versions remain.
/// Multiple uploads of the same song do not require user intervention.
int recordingScore(Track song, OnlineTrack candidate) {
  final identity = song.catalogIdentity;
  if (identity == null || !_sameVersions(song.title, candidate.title)) return 0;
  final artists = {
    ...identity.artists.map((a) => _artistKey(a.name)),
    _artistKey(song.artist),
  }..remove('');
  var title = _recordingTitle(candidate.title);
  final channelCredit = _credited(candidate.artist, artists);
  var titleCredit = false;
  for (final separator in RegExp(r'[-–—|:]').allMatches(title)) {
    if (_credited(title.substring(0, separator.start).trim(), artists)) {
      titleCredit = true;
      title = title.substring(separator.end).trim();
      break;
    }
  }
  final wanted = _text(_recordingTitle(song.title));
  if (wanted.isEmpty ||
      _text(title) != wanted ||
      (!channelCredit && !titleCredit)) {
    return 0;
  }
  final delta = (song.durationSeconds - candidate.durationSeconds).abs();
  final knownDuration =
      song.durationSeconds > 0 && candidate.durationSeconds > 0;
  // Music videos can contain a short intro/outro. A different length still
  // reduces rank, while long versions/full albums are excluded.
  if (knownDuration &&
      delta > math.max(20, math.min(45, song.durationSeconds * .18))) {
    return 0;
  }
  return 100 +
      (channelCredit ? 15 : 0) +
      (titleCredit ? 5 : 0) -
      (knownDuration ? delta ~/ 2 : 15);
}

bool matchesRecording(Track song, OnlineTrack candidate) =>
    recordingScore(song, candidate) > 0;

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
  for (final query in queries) {
    final found = await catalog.search(query);
    for (final value in found) {
      results[value.id] = value;
    }
    if (found.any((t) => matchesRecording(song, t))) break;
  }
  final indexed = results.values.toList().asMap().entries.toList()
    ..sort((a, b) {
      final score = recordingScore(
        song,
        b.value,
      ).compareTo(recordingScore(song, a.value));
      return score != 0 ? score : a.key.compareTo(b.key);
    });
  return indexed.map((entry) => entry.value).toList();
}
