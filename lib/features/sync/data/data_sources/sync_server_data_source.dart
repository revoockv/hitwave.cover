import 'dart:async';
import 'dart:convert';
import 'dart:io';

/// What the hosting device answers to the requests of the other one.
abstract interface class SyncHostHandler {
  /// The other device, called [deviceName], connected.
  void onConnected(String deviceName);

  /// The other device reports what it is doing ([step]).
  void onPeerProgress(String step);

  /// The other device stopped with [message].
  void onPeerFailed(String message);

  /// The snapshot of this device as JSON text.
  Future<String> snapshot();

  /// Path of the file called [name] (a recording file), or `null` when there is none.
  String? filePath(String name);

  /// Stores the file called [name] that the other device sends.
  Future<void> receiveFile(String name, Stream<List<int>> data);

  /// Merges the snapshot of the other device ([json]), which reports what it received
  /// ([receivedJson]); returns what this device added, as JSON text.
  Future<String> receiveSnapshot({required String json, required String receivedJson});
}

/// A small HTTP server on the local network that serves [SyncHostHandler] to one other device.
///
/// Every request must carry the one-time key; file names are checked, so nothing outside the
/// recordings can be read or written. Every answer closes its connection and files are sent with
/// their length, so the other device can tell a cut transfer.
final class SyncServerDataSource {
  /// Header with the one-time key.
  static const String tokenHeader = 'x-hitwave-token';

  /// Header with the name of the device that sends the request (URI-encoded).
  static const String deviceHeader = 'x-hitwave-device';

  /// Header with what the other device received (JSON).
  static const String receivedHeader = 'x-hitwave-received';

  /// Path that checks the connection.
  static const String pingPath = '/ping';

  /// Path of the snapshot.
  static const String snapshotPath = '/snapshot';

  /// Path where the other device reports its progress.
  static const String progressPath = '/progress';

  /// Path where the other device reports that it stopped.
  static const String abortPath = '/abort';

  /// Path prefix of the files.
  static const String filesPath = '/files/';

  static const String _get = 'GET';
  static const String _put = 'PUT';
  static const String _post = 'POST';
  static const String _ok = 'ok';
  static const List<String> _privatePrefixes = <String>['192.168.', '10.', '172.'];
  static final RegExp _fileName = RegExp(r'^[A-Za-z0-9-]+_(raw|enhanced)\.wav$');

  /// Whether the loopback address is offered too (tests on one machine).
  final bool includeLoopback;

  HttpServer? _server;

  /// Creates the server data source.
  SyncServerDataSource({this.includeLoopback = false});

  /// Starts serving [handler] to requests with [token]; returns the port.
  Future<int> start({required String token, required SyncHostHandler handler}) async {
    await stop();
    final HttpServer server = await HttpServer.bind(InternetAddress.anyIPv4, 0);
    _server = server;
    server.listen((HttpRequest request) => unawaited(_handle(request, token, handler)));
    return server.port;
  }

  /// The IPv4 addresses of this device on its networks, private ones first.
  Future<List<String>> localAddresses() async {
    final List<NetworkInterface> interfaces = await NetworkInterface.list(
      type: InternetAddressType.IPv4,
      includeLoopback: includeLoopback,
    );
    final List<String> addresses = <String>[
      for (final NetworkInterface interface in interfaces)
        for (final InternetAddress address in interface.addresses)
          if ((includeLoopback || !address.isLoopback) && !address.isLinkLocal) address.address,
    ];
    addresses.sort((String a, String b) => _rank(a).compareTo(_rank(b)));
    if (includeLoopback) addresses.insert(0, InternetAddress.loopbackIPv4.address);
    return addresses;
  }

  /// Stops the server.
  Future<void> stop() async {
    await _server?.close(force: true);
    _server = null;
  }

  Future<void> _handle(HttpRequest request, String token, SyncHostHandler handler) async {
    final HttpResponse response = request.response..persistentConnection = false;
    try {
      if (request.headers.value(tokenHeader) != token) {
        response.statusCode = HttpStatus.forbidden;
        await response.close();
        return;
      }
      final String path = request.uri.path;
      final String method = request.method;
      if (method == _get && path == pingPath) {
        handler.onConnected(Uri.decodeComponent(request.headers.value(deviceHeader) ?? ''));
        response.write(_ok);
      } else if (method == _get && path == snapshotPath) {
        response.headers.contentType = ContentType.json;
        response.write(await handler.snapshot());
      } else if (method == _post && path == snapshotPath) {
        final String json = await utf8.decodeStream(request);
        final String answer = await handler.receiveSnapshot(
          json: json,
          receivedJson: request.headers.value(receivedHeader) ?? '',
        );
        response.headers.contentType = ContentType.json;
        response.write(answer);
      } else if (method == _post && path == progressPath) {
        handler.onPeerProgress(await utf8.decodeStream(request));
        response.write(_ok);
      } else if (method == _post && path == abortPath) {
        handler.onPeerFailed(await utf8.decodeStream(request));
        response.write(_ok);
      } else if (path.startsWith(filesPath) && _fileName.hasMatch(path.substring(filesPath.length))) {
        final String name = path.substring(filesPath.length);
        if (method == _get) {
          await _sendFile(response, handler.filePath(name));
          return;
        } else if (method == _put) {
          await handler.receiveFile(name, request);
          response.write(_ok);
        } else {
          response.statusCode = HttpStatus.methodNotAllowed;
        }
      } else {
        response.statusCode = HttpStatus.notFound;
      }
      await response.close();
    } on Object {
      await _fail(response);
    }
  }

  /// Sends the file at [path] with its length, or "not found".
  static Future<void> _sendFile(HttpResponse response, String? path) async {
    final File? file = path == null ? null : File(path);
    if (file == null || !await file.exists()) {
      response.statusCode = HttpStatus.notFound;
      await response.close();
      return;
    }
    response.contentLength = await file.length();
    await response.addStream(file.openRead());
    await response.close();
  }

  /// Answers with an error when nothing was sent yet; otherwise cuts the connection, so the
  /// other device sees a short file instead of a broken one.
  static Future<void> _fail(HttpResponse response) async {
    try {
      response.statusCode = HttpStatus.internalServerError;
      await response.close();
    } on Object {
      try {
        (await response.detachSocket(writeHeaders: false)).destroy();
      } on Object {
        // The connection is gone already.
      }
    }
  }

  /// Home networks (192.168…, 10…, 172…) before the others.
  static int _rank(String address) {
    for (int index = 0; index < _privatePrefixes.length; index++) {
      if (address.startsWith(_privatePrefixes[index])) return index;
    }
    return _privatePrefixes.length;
  }
}
