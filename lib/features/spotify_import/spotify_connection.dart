import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:flutter/services.dart';

import 'metadata_import.dart';

const spotifyRedirect = 'it.diegomazzei.aura.spotify://callback';
String _random() => base64Url
    .encode(List.generate(48, (_) => Random.secure().nextInt(256)))
    .replaceAll('=', '');

class SpotifyLogin {
  SpotifyLogin(this.clientId) : verifier = _random(), state = _random();
  final String clientId, verifier, state;
  Uri get url => Uri.https('accounts.spotify.com', '/authorize', {
    'client_id': clientId,
    'response_type': 'code',
    'redirect_uri': spotifyRedirect,
    'code_challenge_method': 'S256',
    'code_challenge': base64Url
        .encode(sha256.convert(ascii.encode(verifier)).bytes)
        .replaceAll('=', ''),
    'state': state,
    'scope':
        'playlist-read-private playlist-read-collaborative user-library-read',
  });
  String callbackCode(String raw) {
    final uri = Uri.parse(raw);
    if (uri.scheme != 'it.diegomazzei.aura.spotify' ||
        uri.host != 'callback' ||
        uri.queryParameters['state'] != state) {
      throw const FormatException('Risposta Spotify non valida');
    }
    final code = uri.queryParameters['code'];
    if (code == null || uri.queryParameters.containsKey('error')) {
      throw const FormatException('Accesso Spotify non autorizzato');
    }
    return code;
  }
}

class SpotifyImportResult {
  SpotifyImportResult(this.collections, this.skipped);
  final List<ImportedCollection> collections;
  final List<String> skipped;
}

class SpotifyConnection {
  static const _auth = MethodChannel('aura/spotify_auth');
  Future<SpotifyImportResult> connectAndImport(
    String clientId, {
    void Function(String)? onProgress,
  }) async {
    if (!RegExp(r'^[a-fA-F0-9]{32}$').hasMatch(clientId)) {
      throw const FormatException('Inserisci un Client ID Spotify valido');
    }
    final login = SpotifyLogin(clientId);
    final callback = await _auth.invokeMethod<String>('authorize', {
      'url': login.url.toString(),
    });
    if (callback == null) throw const FormatException('Accesso annullato');
    final code = login.callbackCode(callback);
    final tokenData = await _request(
      Uri.https('accounts.spotify.com', '/api/token'),
      form: {
        'grant_type': 'authorization_code',
        'code': code,
        'redirect_uri': spotifyRedirect,
        'client_id': clientId,
        'code_verifier': login.verifier,
      },
    );
    final token = tokenData['access_token'];
    if (token is! String) {
      throw const FormatException('Accesso Spotify non riuscito');
    }
    // Tokens are used only for this import, never persisted or logged.
    final collections = <ImportedCollection>[];
    final skipped = <String>[];
    onProgress?.call('Importo i brani preferiti…');
    final saved = await _pages('/v1/me/tracks?limit=50', token);
    final favorites = saved
        .map(spotifyImportedSong)
        .whereType<ImportedSong>()
        .toList();
    if (favorites.isNotEmpty) {
      collections.add(
        ImportedCollection(
          name: 'Brani preferiti · Spotify',
          songs: favorites,
          sourceId: 'saved',
        ),
      );
    }
    final playlists = await _pages('/v1/me/playlists?limit=50', token);
    for (final playlist in playlists) {
      final id = playlist['id'],
          name = playlist['name'] as String? ?? 'Playlist Spotify';
      if (id is! String || !RegExp(r'^[A-Za-z0-9]+$').hasMatch(id)) continue;
      onProgress?.call('Importo $name…');
      try {
        final items = await _pages('/v1/playlists/$id/items?limit=50', token);
        final songs = items
            .map(spotifyImportedSong)
            .whereType<ImportedSong>()
            .toList();
        if (songs.isNotEmpty) {
          collections.add(
            ImportedCollection(name: name, songs: songs, sourceId: id),
          );
        }
      } on SpotifyUnavailable {
        skipped.add(name);
      }
    }
    return SpotifyImportResult(collections, skipped);
  }

  Future<List<Map>> _pages(String path, String token) async {
    Uri? uri = Uri.parse('https://api.spotify.com$path');
    final seen = <String>{};
    final result = <Map>[];
    while (uri != null) {
      if (!seen.add(uri.toString()) || seen.length > 1000) {
        throw const FormatException('Importazione troppo grande');
      }
      if (uri.scheme != 'https' ||
          uri.host != 'api.spotify.com' ||
          uri.port != 443 ||
          uri.userInfo.isNotEmpty ||
          !uri.path.startsWith('/v1/')) {
        throw const FormatException('Pagina Spotify non valida');
      }
      final page = await _request(uri, token: token);
      result.addAll((page['items'] as List? ?? []).whereType<Map>());
      uri = page['next'] is String ? Uri.parse(page['next'] as String) : null;
    }
    return result;
  }

  Future<Map> _request(
    Uri uri, {
    String? token,
    Map<String, String>? form,
  }) async {
    final client = HttpClient()
      ..connectionTimeout = const Duration(seconds: 15);
    try {
      final request = await client.openUrl(form == null ? 'GET' : 'POST', uri);
      request.followRedirects = false;
      if (token != null) request.headers.set('Authorization', 'Bearer $token');
      if (form != null) {
        request.headers.contentType = ContentType(
          'application',
          'x-www-form-urlencoded',
        );
        request.write(Uri(queryParameters: form).query);
      }
      final response = await request.close().timeout(
        const Duration(seconds: 20),
      );
      if (response.statusCode == 403) throw SpotifyUnavailable();
      if (response.statusCode == 429) {
        throw const FormatException(
          'Spotify richiede una pausa. Riprova più tardi.',
        );
      }
      if (response.statusCode != 200) {
        throw const FormatException(
          'Spotify non ha completato l’importazione. Controlla accesso e configurazione.',
        );
      }
      final bytes = <int>[];
      await for (final chunk in response.timeout(const Duration(seconds: 20))) {
        bytes.addAll(chunk);
        if (bytes.length > 4 * 1024 * 1024) {
          throw const FormatException('Risposta Spotify troppo grande');
        }
      }
      final json = jsonDecode(utf8.decode(bytes));
      if (json is! Map) {
        throw const FormatException('Risposta Spotify non valida');
      }
      return json;
    } finally {
      client.close(force: true);
    }
  }
}

class SpotifyUnavailable implements Exception {}

ImportedSong? spotifyImportedSong(Map row) {
  final raw = row['item'] ?? row['track'] ?? row;
  if (raw is! Map || raw['type'] == 'episode' || raw['is_local'] == true) {
    return null;
  }
  final title = raw['name'];
  final artist = (raw['artists'] as List? ?? [])
      .whereType<Map>()
      .map((a) => a['name'])
      .whereType<String>()
      .join(', ');
  if (title is! String || artist.isEmpty) return null;
  return ImportedSong(
    title: title,
    artist: artist,
    album: raw['album'] is Map ? (raw['album']['name'] as String? ?? '') : '',
    uri: raw['uri'] as String? ?? '',
    durationSeconds: ((raw['duration_ms'] as num? ?? 0) / 1000).round(),
  );
}
