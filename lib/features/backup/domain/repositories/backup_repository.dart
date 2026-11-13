import 'package:flutter/foundation.dart' show ValueListenable;

import '../../../../core/domain/entities/result.dart';
import '../entities/backup_failure.dart';

/// Defines the contract for backup and restore operations via files.
///
/// Implementations handle exporting songs to a JSON file and importing
/// songs from a JSON file, persisting them to Firebase. File picker
/// operations are encapsulated within the repository — no file paths
/// are exposed to the interface.
abstract interface class BackupRepository {
  /// The current backup status.
  ///
  /// Holds a [String] describing the current state: idle, exporting,
  /// importing, success, or an error message.
  ValueListenable<String> watchStatus();

  /// Exports all songs to a JSON file in a user-selected directory.
  ///
  /// Prompts the user to select an export directory via file picker,
  /// then writes all songs to a `backup.json` file within that directory.
  /// Returns [SuccessResult] on success, or [FailureResult] with an error
  /// message when the export fails.
  ///
  /// With [includeRecordings], the recordings of the songs are added and the file becomes a
  /// `backup.zip` with their WAV files (only where the device has a file system).
  Future<Result<void, BackupFailure>> exportSongs({required bool includeRecordings, required String pickerTitle});

  /// Imports songs from a user-selected JSON file.
  ///
  /// Prompts the user to select a backup file via file picker, reads
  /// the backup data, and adds all songs to Firebase. Returns
  /// [SuccessResult] on success, or [FailureResult] with an error
  /// message when the import fails.
  ///
  /// A `backup.zip` may hold recordings; they are added only with [includeRecordings].
  Future<Result<void, BackupFailure>> importSongs({required bool includeRecordings});

  /// Makes a backup of the songs (a ZIP with the takes when [includeRecordings]) and opens the
  /// share sheet with it, so it can go to Google Drive or another app.
  Future<Result<void, BackupFailure>> shareBackup({required bool includeRecordings});
}
