import 'dart:convert';
import 'dart:io';

import 'sync_server_data_source.dart';

/// Talks to the [SyncServerDataSource] of the other device.
final class SyncClientDataSource {
  static const Duration _connectTimeout = Duration(seconds: 3);
  static const String _http = 'http';
  static const String _unreachableError =
      'Не вдалося підключитися до пристрою. Перевірте, що обидва в одній мережі Wi‑Fi.';
  static const String _statusError = 'Пристрій відповів помилкою ';

  final HttpClient _client = HttpClient()..connectionTimeout = _connectTimeout;

  /// The first of [addresses] that answers on [port] with [token]; throws when none does.
  Future<Uri> connect({required List<String> addresses, required int port, required String token}) async {
    for (final String address in addresses) {
      final Uri base = Uri(scheme: _http, host: address, port: port);
      try {
        await _send(base.replace(path: SyncServerDataSource.pingPath), token, _get);
        return base;
      } on Exception {
        continue;
      }
    }
    throw const SocketException(_unreachableError);
  }

  /// The snapshot of the other device as JSON text.
  Future<String> snapshot(Uri base, String token) =>
      _send(base.replace(path: SyncServerDataSource.snapshotPath), token, _get);

  /// Downloads the file [name] of the other device into [to].
  Future<void> download({required Uri base, required String token, required String name, required File to}) async {
    final HttpClientRequest request = await _client.getUrl(
      base.replace(path: '${SyncServerDataSource.filesPath}$name'),
    );
    request.headers.set(SyncServerDataSource.tokenHeader, token);
    final HttpClientResponse response = await request.close();
    _check(response);
    await response.pipe(to.openWrite());
  }

  /// Uploads [from] to the other device as [name].
  Future<void> upload({required Uri base, required String token, required String name, required File from}) async {
    final HttpClientRequest request = await _client.putUrl(
      base.replace(path: '${SyncServerDataSource.filesPath}$name'),
    );
    request.headers.set(SyncServerDataSource.tokenHeader, token);
    request.contentLength = await from.length();
    await request.addStream(from.openRead());
    final HttpClientResponse response = await request.close();
    _check(response);
    await response.drain<void>();
  }

  /// Sends the snapshot of this device ([json]) and what it received ([receivedJson]); returns
  /// what the other device added, as JSON text.
  Future<String> sendSnapshot({
    required Uri base,
    required String token,
    required String json,
    required String receivedJson,
  }) async {
    final HttpClientRequest request = await _client.postUrl(base.replace(path: SyncServerDataSource.snapshotPath));
    request.headers.set(SyncServerDataSource.tokenHeader, token);
    request.headers.set(SyncServerDataSource.receivedHeader, receivedJson);
    request.headers.contentType = ContentType.json;
    request.write(json);
    final HttpClientResponse response = await request.close();
    _check(response);
    return utf8.decodeStream(response);
  }

  static const String _get = 'GET';

  Future<String> _send(Uri uri, String token, String method) async {
    final HttpClientRequest request = await _client.openUrl(method, uri);
    request.headers.set(SyncServerDataSource.tokenHeader, token);
    final HttpClientResponse response = await request.close();
    _check(response);
    return utf8.decodeStream(response);
  }

  static void _check(HttpClientResponse response) {
    if (response.statusCode != HttpStatus.ok) throw HttpException('$_statusError${response.statusCode}');
  }
}
