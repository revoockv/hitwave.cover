import 'dart:convert';

import '../../../song/domain/entities/song.dart';
import '../../domain/entities/backup_data.dart';
import 'backup_recording_model.dart';
import 'backup_song_model.dart';

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

  /// JSON key for backup version.
  static const String _versionKey = 'version';

  /// The timestamp when this backup was created.
  final DateTime exportedAt;

  /// The songs of this backup.
  final List<BackupSongModel> songs;

  /// The recordings of the songs, with their file names in the archive.
  final List<BackupRecordingModel> recordings;

  /// Creates a new [BackupDataModel] instance.
  const BackupDataModel({
    required this.exportedAt,
    required this.songs,
    this.recordings = const <BackupRecordingModel>[],
  });

  /// Converts this model to a domain [BackupData] entity.
  BackupData toEntity() {
    return BackupData(exportedAt: exportedAt, songs: songs.map(_songOf).toList());
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
      songs: (data[_songsField] as List<dynamic>).map(BackupSongModel.fromJson).toList(),
      recordings: (data[_recordingsField] as List<dynamic>? ?? const <dynamic>[])
          .map(BackupRecordingModel.fromJson)
          .toList(),
    );
  }

  /// Encodes this model to a JSON string; indented by [indent] when given (a file people may read).
  String toJson({String? indent}) {
    final Map<String, dynamic> json = <String, dynamic>{
      _versionKey: version,
      _exportedAtField: exportedAt.toIso8601String(),
      _songsField: songs.map(_songJson).toList(),
      if (recordings.isNotEmpty) _recordingsField: recordings.map(_recordingJson).toList(),
    };
    return indent == null ? jsonEncode(json) : JsonEncoder.withIndent(indent).convert(json);
  }

  static Song _songOf(BackupSongModel song) => song.toEntity();

  static Map<String, dynamic> _songJson(BackupSongModel song) => song.toJson();

  static Map<String, dynamic> _recordingJson(BackupRecordingModel recording) => recording.toJson();
}
