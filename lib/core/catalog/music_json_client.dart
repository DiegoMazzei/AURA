import 'dart:async';
import 'dart:convert';
import 'dart:io';

abstract class MusicJsonClient {
  Future<Object?> get(Uri uri);
}

class MusicServiceException implements Exception {
  const MusicServiceException(this.message);
  final String message;
  @override
  String toString() => message;
}

/// Sequential, identified requests; honors Retry-After without retry storms.
class PublicMusicJsonClient implements MusicJsonClient {
  Future<void> _pending = Future.value();
  final Map<String, DateTime> _lastRequest = {}, _blockedUntil = {};
  @override
  Future<Object?> get(Uri uri) {
    final result = Completer<Object?>();
    _pending = _pending.then((_) async {
      try {
        result.complete(await _get(uri));
      } catch (e, st) {
        result.completeError(e, st);
      }
    });
    return result.future;
  }

  Future<Object?> _get(Uri uri) async {
    final host = uri.host;
    if (uri.scheme != 'https' ||
        !{
          'musicbrainz.org',
          'lrclib.net',
          'itunes.apple.com',
          'www.theaudiodb.com',
          'api.deezer.com',
        }.contains(host)) {
      throw const MusicServiceException('Fonte musicale non supportata.');
    }
    final blocked = _blockedUntil[host];
    if (blocked != null && blocked.isAfter(DateTime.now())) {
      throw const MusicServiceException(
        'Il catalogo è occupato. Riprova più tardi.',
      );
    }
    final interval = host == 'www.theaudiodb.com'
        ? 2100
        : host == 'api.deezer.com'
        ? 550
        : host == 'musicbrainz.org'
        ? 1100
        : host == 'itunes.apple.com'
        ? 3100
        : 350;
    final previous = _lastRequest[host];
    if (previous != null) {
      final delay =
          interval - DateTime.now().difference(previous).inMilliseconds;
      if (delay > 0) await Future<void>.delayed(Duration(milliseconds: delay));
    }
    _lastRequest[host] = DateTime.now();
    final client = HttpClient()
      ..connectionTimeout = const Duration(seconds: 10);
    try {
      final request = await client.getUrl(uri);
      request.headers.set(
        'User-Agent',
        'AURA/0.2 (https://github.com/DiegoMazzei)',
      );
      request.headers.set('Accept', 'application/json');
      final response = await request.close().timeout(
        const Duration(seconds: 12),
      );
      if (response.statusCode == 429 || response.statusCode == 503) {
        final raw = response.headers.value('retry-after') ?? '';
        final seconds = int.tryParse(raw);
        DateTime? date;
        try {
          date = HttpDate.parse(raw);
        } catch (_) {}
        _blockedUntil[host] =
            date ??
            DateTime.now().add(
              Duration(seconds: (seconds ?? 60).clamp(30, 3600)),
            );
        throw const MusicServiceException(
          'Il catalogo è occupato. Riprova più tardi.',
        );
      }
      if (response.statusCode == 404) return null;
      if (response.statusCode != 200) {
        throw const MusicServiceException(
          'La fonte musicale non è disponibile.',
        );
      }
      final bytes = <int>[];
      await for (final chunk in response.timeout(const Duration(seconds: 12))) {
        bytes.addAll(chunk);
        if (bytes.length > 2 * 1024 * 1024) {
          throw const MusicServiceException('Risposta troppo grande.');
        }
      }
      return jsonDecode(utf8.decode(bytes));
    } finally {
      client.close(force: true);
    }
  }
}
