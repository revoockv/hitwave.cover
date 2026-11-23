import 'dart:convert';

/// What the QR code of the hosting device holds: its addresses, the port and a one-time key.
///
/// Written as `hitwave-sync:<base64url JSON>`, so it can also be copied and typed by hand.
final class SyncOfferModel {
  static const String _prefix = 'hitwave-sync:';
  static const String _addressesField = 'a';
  static const String _portField = 'p';
  static const String _tokenField = 't';
  static const String _deviceField = 'd';
  static const String _padding = '=';
  static const String _notACodeError = 'Not a sync code of hitwave.cover';

  /// IPv4 addresses of the hosting device on its networks.
  final List<String> addresses;

  /// Port of its server.
  final int port;

  /// One-time key every request carries.
  final String token;

  /// Name of the hosting device.
  final String deviceName;

  /// Creates a [SyncOfferModel].
  const SyncOfferModel({required this.addresses, required this.port, required this.token, required this.deviceName});

  /// Reads a code; throws a [FormatException] when it is no sync code.
  factory SyncOfferModel.decode(String code) {
    final String text = code.trim();
    if (!text.startsWith(_prefix)) throw const FormatException(_notACodeError);
    try {
      final Map<String, dynamic> json =
          jsonDecode(utf8.decode(base64Url.decode(base64Url.normalize(text.substring(_prefix.length)))))
              as Map<String, dynamic>;
      return SyncOfferModel(
        addresses: (json[_addressesField] as List<dynamic>).cast<String>(),
        port: json[_portField] as int,
        token: json[_tokenField] as String,
        deviceName: json[_deviceField] as String? ?? '',
      );
    } on Object {
      throw const FormatException(_notACodeError);
    }
  }

  /// The code to show as a QR code.
  String encode() {
    final String json = jsonEncode(<String, dynamic>{
      _addressesField: addresses,
      _portField: port,
      _tokenField: token,
      _deviceField: deviceName,
    });
    return '$_prefix${base64Url.encode(utf8.encode(json)).replaceAll(_padding, '')}';
  }
}
