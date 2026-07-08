import 'package:flutter/foundation.dart' show ValueNotifier;

import '../../../../core/domain/result.dart';

/// Defines the contract for backup and restore operations via files.
///
/// Implementations handle exporting songs to a JSON file and importing
/// songs from a JSON file, persisting them to Firebase.
abstract interface class BackupRepository {
  /// Returns the current backup status as a [ValueNotifier].
  ///
  /// Contains a [String] describing the current state: idle, exporting,
  /// importing, success, or error message.
  ValueNotifier<String> get status;

  /// Exports all songs to a JSON file at the given [filePath].
  ///
  /// Returns [SuccessResult] on success, or [FailureResult] with an error
  /// message when the export fails.
  Future<Result<void>> exportSongs(String filePath);

  /// Imports songs from a JSON file at the given [filePath].
  ///
  /// Reads the backup file, parses it, and adds all songs to Firebase.
  /// Returns [SuccessResult] on success, or [FailureResult] with an error
  /// message when the import fails.
  Future<Result<void>> importSongs(String filePath);
}
