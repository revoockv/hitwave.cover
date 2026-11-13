import 'dart:convert';

import 'package:hitwave.cover/features/song/domain/entities/cover.dart';
import 'package:hitwave.cover/features/song/domain/entities/song.dart';

import '../../domain/entities/backup_data.dart';

/// Data transfer object representing a backup payload as JSON.
///
/// Handles serialization and deserialization of backup data to/from JSON
/// strings for file-based export and import operations.
final class BackupDataModel {
  /// The schema version of this backup format.
  static const String version = '1.1';

  /// Firestore field name for export timestamp.
  static const String _exportedAtField = 'exportedAt';

  /// Firestore field name for songs list.
  static const String _songsField = 'songs';

  /// Field of the recordings list (only in a ZIP backup).
  static const String _recordingsField = 'recordings';

  /// Firestore field name for song ID.
  static const String _idField = 'id';

  /// Firestore field name for song author.
  static const String _authorField = 'author';

  /// Firestore field name for song name.
  static const String _nameField = 'name';

  /// Firestore field name for song album.
  static const String _albumField = 'album';

  /// Firestore field name for song lyrics.
  static const String _lyricsField = 'lyrics';

  /// Firestore field name for cover IDs array.
  static const String _coverIdsField = 'coverIds';

  /// JSON key for backup version.
  static const String _versionKey = 'version';

  /// The timestamp when this backup was created.
  final DateTime exportedAt;

  /// The list of songs included in this backup.
  final List<Map<String, dynamic>> songs;

  /// The recordings of the songs: one map per recording with its file names in the archive.
  final List<Map<String, dynamic>> recordings;

  /// Creates a new [BackupDataModel] instance.
  const BackupDataModel({
    required this.exportedAt,
    required this.songs,
    this.recordings = const <Map<String, dynamic>>[],
  });

  /// Converts this model to a domain [BackupData] entity.
  BackupData toEntity() {
    return BackupData(exportedAt: exportedAt, songs: songs.map(_decodeSong).toList());
  }

  /// Creates a [BackupDataModel] from a JSON string.
  ///
  /// Handles both raw JSON strings and double-encoded JSON strings
  /// (where the file contains a JSON string wrapping another JSON string).
  factory BackupDataModel.fromJson(String json) {
    Map<String, dynamic> data;

    try {
      data = Map<String, dynamic>.from(jsonDecode(json) as Map);
    } catch (_) {
      // Try to unwrap double-encoded JSON (string containing a JSON string)
      final String unwrapped = jsonDecode(json) as String;
      data = Map<String, dynamic>.from(jsonDecode(unwrapped) as Map);
    }

    return BackupDataModel(
      exportedAt: DateTime.parse(data[_exportedAtField] as String),
      songs: List<Map<String, dynamic>>.from(data[_songsField] as List),
      recordings: List<Map<String, dynamic>>.from(data[_recordingsField] as List? ?? const <dynamic>[]),
    );
  }

  /// Encodes this model to a JSON string.
  String toJson() {
    return jsonEncode(<String, dynamic>{
      _versionKey: version,
      _exportedAtField: exportedAt.toIso8601String(),
      _songsField: songs,
      if (recordings.isNotEmpty) _recordingsField: recordings,
    });
  }

  /// Decodes a single song map into a [Song] entity.
  Song _decodeSong(Map<String, dynamic> songData) {
    return Song(
      id: songData[_idField] as String,
      author: songData[_authorField] as String,
      name: songData[_nameField] as String,
      album: songData[_albumField] as String?,
      lyrics: songData[_lyricsField] as String,
      covers: List<String>.from(
        songData[_coverIdsField] as List<dynamic>,
      ).map((coverId) => Cover(id: coverId, date: DateTime.now(), audioBytes: const [], notes: null)).toList(),
    );
  }
}
