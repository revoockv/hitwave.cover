/// A recording read from a backup archive or received from another device, to be added to the
/// library of this device.
final class ImportedRecording {
  /// Id to keep (a recording synced from another device), or `null` for a new one. A recording
  /// whose id is already in the library is skipped.
  final String? id;

  /// The song it belongs to (its id on this device).
  final String songId;

  /// When it was recorded.
  final DateTime recordedAt;

  /// Length of the raw take in seconds.
  final double durationSeconds;

  /// The extracted raw WAV file; it is moved into the library.
  final String rawFilePath;

  /// The extracted enhanced WAV file, if the backup had one; moved into the library.
  final String? enhancedFilePath;

  /// Where the enhanced file starts in the raw take, in seconds.
  final double keptFromSeconds;

  /// Where the enhanced file ends in the raw take, in seconds; `null` = the end.
  final double? keptToSeconds;

  /// Creates an [ImportedRecording].
  const ImportedRecording({
    this.id,
    required this.songId,
    required this.recordedAt,
    required this.durationSeconds,
    required this.rawFilePath,
    required this.enhancedFilePath,
    required this.keptFromSeconds,
    required this.keptToSeconds,
  });
}
