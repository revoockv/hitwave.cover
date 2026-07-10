/// Defines the contract for file picker operations used in backup workflows.
///
/// Implementations handle picking files for import and picking directories
/// for export, using platform-agnostic file picker APIs.
abstract interface class BackupDataSource {
  /// Picks a JSON file from the file system and returns its content as a string.
  ///
  /// Returns `null` if the user cancels the picker or no file is selected.
  Future<String?> pickBackupFile();

  /// Picks a directory from the file system and returns its path.
  ///
  /// Returns `null` if the user cancels the picker or no directory is selected.
  Future<String?> pickExportDirectory();
}
