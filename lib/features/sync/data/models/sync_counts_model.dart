import 'dart:convert';

/// How many songs, covers and practice sessions one side added.
final class SyncCountsModel {
  static const String _songsField = 'songs';
  static const String _coversField = 'covers';
  static const String _sessionsField = 'sessions';

  /// Songs added.
  final int songs;

  /// Covers added.
  final int covers;

  /// Practice sessions added.
  final int sessions;

  /// Creates a [SyncCountsModel].
  const SyncCountsModel({required this.songs, required this.covers, required this.sessions});

  /// Reads the JSON text of another device.
  factory SyncCountsModel.fromJsonText(String text) {
    final Map<String, dynamic> json = jsonDecode(text) as Map<String, dynamic>;
    return SyncCountsModel(
      songs: json[_songsField] as int,
      covers: json[_coversField] as int,
      sessions: json[_sessionsField] as int,
    );
  }

  /// The JSON text to send.
  String toJsonText() =>
      jsonEncode(<String, dynamic>{_songsField: songs, _coversField: covers, _sessionsField: sessions});
}
