import 'package:flutter/foundation.dart' show ValueListenable;

import '../../../../core/domain/entities/result.dart';
import '../entities/backup_failure.dart';
import '../entities/import_choice.dart';
import '../entities/import_conflict.dart';
import '../entities/import_plan.dart';
import '../entities/import_summary.dart';

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

  /// Lets the user pick a backup file (`backup.json`, or `backup.zip` with takes) and reads it.
  ///
  /// Nothing is imported yet: the plan lists the songs already in the library, and
  /// [applyImport] or [cancelImport] follows. Returns `null` when the user cancelled the picker.
  /// With [includeRecordings] the takes of a ZIP backup are imported too.
  Future<Result<ImportPlan?, BackupFailure>> openImport({required bool includeRecordings});

  /// Imports the backup opened by [openImport]. [choices] says what to do with each conflict
  /// (by [ImportConflict.index]); a conflict without a choice is skipped.
  Future<Result<ImportSummary, BackupFailure>> applyImport(Map<int, ImportChoice> choices);

  /// Drops the backup opened by [openImport] without importing anything.
  Future<void> cancelImport();

  /// Makes a backup of the songs (a ZIP with the takes when [includeRecordings]) and opens the
  /// share sheet with it, so it can go to Google Drive or another app.
  Future<Result<void, BackupFailure>> shareBackup({required bool includeRecordings});
}
