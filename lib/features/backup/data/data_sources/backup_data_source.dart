import 'dart:typed_data';

/// A backup file the user picked: its [name], and its [path] (desktop, mobile) or its [bytes] (web).
final class PickedBackupFile {
  /// File name with the extension.
  final String name;

  /// Full path on the device, when the platform gives one.
  final String? path;

  /// The content, when the platform gives no path (web).
  final Uint8List? bytes;

  /// Creates a [PickedBackupFile].
  const PickedBackupFile({required this.name, required this.path, required this.bytes});
}

/// Defines the contract for file picker operations used in backup workflows.
///
/// Implementations handle picking files for import and picking directories
/// for export, using platform-agnostic file picker APIs.
abstract interface class BackupDataSource {
  /// Whether this platform supports directory selection for export.
  ///
  /// On web, directory selection is unavailable (browsers can't access
  /// the file system hierarchy), so this returns `false`. The repository
  /// will skip directory selection and trigger a browser download directly.
  bool get supportsDirectorySelection;

  /// Picks a backup file (`.json`, or `.zip` with recordings).
  ///
  /// Returns `null` if the user cancels the picker or no file is selected.
  Future<PickedBackupFile?> pickBackupFile();

  /// Picks a directory for the export and returns its path.
  ///
  /// Returns `null` if the user cancels the picker or no directory is selected.
  Future<String?> pickExportDirectory();

  /// Triggers a browser download with the given JSON string.
  ///
  /// On mobile/desktop this is a no-op (files are written to disk directly).
  /// On web this creates a Blob, generates an object URL, and triggers
  /// a download via a hidden anchor element.
  Future<void> triggerExportDownload(String jsonString);
}
