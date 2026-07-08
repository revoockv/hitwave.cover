import 'package:hitwave.cover/features/song/domain/entities/song.dart';

/// Represents a backup of songs for import/export operations.
///
/// Contains the export version, timestamp, and a list of songs with their
/// cover IDs. This is serialized to and from JSON files.
final class BackupData {
  /// The schema version of this backup format.
  static const String version = '1.0';

  /// The timestamp when this backup was created.
  final DateTime exportedAt;

  /// The list of songs included in this backup.
  final List<Song> songs;

  /// Creates a new [BackupData] instance.
  const BackupData({
    required this.exportedAt,
    required this.songs,
  });
}
