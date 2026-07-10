import 'package:flutter/foundation.dart' show ValueNotifier;

import '../../../../core/domain/result.dart';

/// Defines the contract for backup and restore operations via files.
///
/// Implementations handle exporting songs to a JSON file and importing
/// songs from a JSON file, persisting them to Firebase. File picker
/// operations are encapsulated within the repository — no file paths
/// are exposed to the interface.
abstract interface class BackupRepository {
  /// Returns the current backup status as a [ValueNotifier].
  ///
  /// Contains a [String] describing the current state: idle, exporting,
  /// importing, success, or error message.
  ValueNotifier<String> get status;

  /// Exports all songs to a JSON file in a user-selected directory.
  ///
  /// Prompts the user to select an export directory via file picker,
  /// then writes all songs to a `backup.json` file within that directory.
  /// Returns [SuccessResult] on success, or [FailureResult] with an error
  /// message when the export fails.
  Future<Result<void>> exportSongs();

  /// Imports songs from a user-selected JSON file.
  ///
  /// Prompts the user to select a backup file via file picker, reads
  /// the backup data, and adds all songs to Firebase. Returns
  /// [SuccessResult] on success, or [FailureResult] with an error
  /// message when the import fails.
  Future<Result<void>> importSongs();
}
