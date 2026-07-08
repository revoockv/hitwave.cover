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
  static const String version = '1.0';

  /// Firestore field name for export timestamp.
  static const String _exportedAtField = 'exportedAt';

  /// Firestore field name for songs list.
  static const String _songsField = 'songs';

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

  /// Creates a new [BackupDataModel] instance.
  const BackupDataModel({
    required this.exportedAt,
    required this.songs,
  });

  /// Converts this model to a domain [BackupData] entity.
  BackupData toEntity() {
    return BackupData(
      exportedAt: exportedAt,
      songs: songs.map(_decodeSong).toList(),
    );
  }

  /// Creates a [BackupDataModel] from a JSON string.
  factory BackupDataModel.fromJson(String json) {
    final Map<String, dynamic> data = Map<String, dynamic>.from(
      jsonDecode(json) as Map,
    );

    return BackupDataModel(
      exportedAt: DateTime.parse(data[_exportedAtField] as String),
      songs: List<Map<String, dynamic>>.from(data[_songsField] as List),
    );
  }

  /// Encodes this model to a JSON string.
  String toJson() {
    return jsonEncode(<String, dynamic>{
      _versionKey: version,
      _exportedAtField: exportedAt.toIso8601String(),
      _songsField: songs,
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
      covers: List<String>.from(songData[_coverIdsField] as List<dynamic>)
          .map((coverId) => Cover(id: coverId, date: DateTime.now(), audioBytes: const [], notes: null))
          .toList(),
    );
  }
}
