import 'dart:convert';

/// How many songs, covers and practice sessions one side added.
final class SyncCountsModel {
  static const String _songsField = 'songs';
  static const String _coversField = 'covers';
  static const String _sessionsField = 'sessions';
  static const String _deletedField = 'deleted';
  static const String _updatedField = 'updated';

  /// Songs added.
  final int songs;

  /// Covers added.
  final int covers;

  /// Practice sessions added.
  final int sessions;

  /// Songs and covers deleted.
  final int deleted;

  /// Songs updated.
  final int updated;

  /// Creates a [SyncCountsModel].
  const SyncCountsModel({
    required this.songs,
    required this.covers,
    required this.sessions,
    this.deleted = 0,
    this.updated = 0,
  });

  /// These counts with [deleted] and [updated] added.
  SyncCountsModel plus({required int deleted, required int updated}) => SyncCountsModel(
    songs: songs,
    covers: covers,
    sessions: sessions,
    deleted: this.deleted + deleted,
    updated: this.updated + updated,
  );

  /// Reads the JSON text of another device.
  factory SyncCountsModel.fromJsonText(String text) {
    final Map<String, dynamic> json = jsonDecode(text) as Map<String, dynamic>;
    return SyncCountsModel(
      songs: json[_songsField] as int,
      covers: json[_coversField] as int,
      sessions: json[_sessionsField] as int,
      deleted: json[_deletedField] as int? ?? 0,
      updated: json[_updatedField] as int? ?? 0,
    );
  }

  /// The JSON text to send.
  String toJsonText() => jsonEncode(<String, dynamic>{
    _songsField: songs,
    _coversField: covers,
    _sessionsField: sessions,
    _deletedField: deleted,
    _updatedField: updated,
  });
}
