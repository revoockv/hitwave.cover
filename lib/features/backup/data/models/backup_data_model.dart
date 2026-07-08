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
      exportedAt: DateTime.parse(data['exportedAt'] as String),
      songs: List<Map<String, dynamic>>.from(data['songs'] as List),
    );
  }

  /// Encodes this model to a JSON string.
  String toJson() {
    return jsonEncode(<String, dynamic>{
      'version': version,
      'exportedAt': exportedAt.toIso8601String(),
      'songs': songs,
    });
  }

  /// Decodes a single song map into a [Song] entity.
  Song _decodeSong(Map<String, dynamic> songData) {
    return Song(
      id: songData['id'] as String,
      author: songData['author'] as String,
      name: songData['name'] as String,
      album: songData['album'] as String?,
      lyrics: songData['lyrics'] as String,
      covers: List<String>.from(songData['coverIds'] as List<dynamic>)
          .map((coverId) => Cover(id: coverId, date: DateTime.now(), audioBytes: const [], notes: null))
          .toList(),
    );
  }
}
