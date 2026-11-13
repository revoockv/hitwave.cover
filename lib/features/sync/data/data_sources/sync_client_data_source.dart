import 'dart:convert';
import 'dart:io';

import 'sync_server_data_source.dart';

/// Talks to the [SyncServerDataSource] of the other device.
///
/// Every request uses its own connection; a downloaded file must have the length the other
/// device announced, otherwise the download fails (and the caller may try again).
final class SyncClientDataSource {
  static const Duration _connectTimeout = Duration(seconds: 3);
  static const String _http = 'http';
  static const String _get = 'GET';
  static const String _post = 'POST';
  static const String _put = 'PUT';
  static const String _unreachableError =
      'Не вдалося підключитися до пристрою. Перевірте, що обидва в одній мережі Wi‑Fi.';
  static const String _statusError = 'Пристрій відповів помилкою ';
  static const String _shortFileError = 'Файл передався не повністю: ';
  static const String _space = ' ';
  static const String _of = '/';

  final HttpClient _client = HttpClient()..connectionTimeout = _connectTimeout;

  /// Name of this device, sent with every request.
  final String deviceName;

  /// Creates the client data source.
  SyncClientDataSource({this.deviceName = ''});

  /// The first of [addresses] that answers on [port] with [token]; throws when none does.
  Future<Uri> connect({required List<String> addresses, required int port, required String token}) async {
    for (final String address in addresses) {
      final Uri base = Uri(scheme: _http, host: address, port: port);
      try {
        await _text(_get, base.replace(path: SyncServerDataSource.pingPath), token);
        return base;
      } on Exception {
        continue;
      }
    }
    throw const SocketException(_unreachableError);
  }

  /// The snapshot of the other device as JSON text.
  Future<String> snapshot(Uri base, String token) =>
      _text(_get, base.replace(path: SyncServerDataSource.snapshotPath), token);

  /// Tells the other device what this one is doing; a lost report is no failure.
  Future<void> progress(Uri base, String token, String step) async {
    try {
      await _text(_post, base.replace(path: SyncServerDataSource.progressPath), token, body: step);
    } on Exception {
      // Only a status line on the other screen.
    }
  }

  /// Tells the other device that this one stopped with [message]; a lost report is no failure.
  Future<void> abort(Uri base, String token, String message) async {
    try {
      await _text(_post, base.replace(path: SyncServerDataSource.abortPath), token, body: message);
    } on Exception {
      // The other device times out on its own screen.
    }
  }

  /// Downloads the file [name] of the other device into [to].
  Future<void> download({required Uri base, required String token, required String name, required File to}) async {
    final HttpClientRequest request = await _open(
      _get,
      base.replace(path: '${SyncServerDataSource.filesPath}$name'),
      token,
    );
    final HttpClientResponse response = await request.close();
    _check(response);
    await response.pipe(to.openWrite());
    final int expected = response.contentLength;
    final int got = await to.length();
    if (expected >= 0 && got != expected) throw HttpException('$_shortFileError$name$_space$got$_of$expected');
  }

  /// Uploads [from] to the other device as [name].
  Future<void> upload({required Uri base, required String token, required String name, required File from}) async {
    final HttpClientRequest request = await _open(
      _put,
      base.replace(path: '${SyncServerDataSource.filesPath}$name'),
      token,
    );
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
  }) => _text(
    _post,
    base.replace(path: SyncServerDataSource.snapshotPath),
    token,
    body: json,
    headers: <String, String>{SyncServerDataSource.receivedHeader: receivedJson},
  );

  Future<HttpClientRequest> _open(String method, Uri uri, String token) async {
    final HttpClientRequest request = await _client.openUrl(method, uri);
    request.persistentConnection = false;
    request.headers.set(SyncServerDataSource.tokenHeader, token);
    request.headers.set(SyncServerDataSource.deviceHeader, Uri.encodeComponent(deviceName));
    return request;
  }

  Future<String> _text(
    String method,
    Uri uri,
    String token, {
    String? body,
    Map<String, String> headers = const <String, String>{},
  }) async {
    final HttpClientRequest request = await _open(method, uri, token);
    headers.forEach(request.headers.set);
    if (body != null) {
      final List<int> bytes = utf8.encode(body);
      request.contentLength = bytes.length;
      request.add(bytes);
    }
    final HttpClientResponse response = await request.close();
    _check(response);
    return utf8.decodeStream(response);
  }

  static void _check(HttpClientResponse response) {
    if (response.statusCode != HttpStatus.ok) throw HttpException('$_statusError${response.statusCode}');
  }
}
