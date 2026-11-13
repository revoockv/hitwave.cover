import 'dart:io';

import 'package:file_picker/file_picker.dart';

import 'backup_data_source.dart';

/// [BackupDataSource] of the platforms with a file system (mobile and desktop).
///
/// Picks a backup file for import (its path is returned, the repository reads it) and a
/// directory for export.
final class BackupDataSourceMobile implements BackupDataSource {
  static const List<String> _allowedExtensions = <String>['json', 'zip'];
  static const String _exportDialogTitle = 'Оберіть папку для експорту';
  static const String _tempPrefix = 'hitwave_picked_';
  static const String _separator = '/';

  @override
  bool get supportsDirectorySelection => true;

  @override
  Future<PickedBackupFile?> pickBackupFile() async {
    final PlatformFile? file = await FilePicker.pickFile(type: FileType.custom, allowedExtensions: _allowedExtensions);
    if (file == null) return null;
    return PickedBackupFile(name: file.name, path: file.path ?? await _copyToTemp(file), bytes: null);
  }

  /// Copies a picked file that has no path on disk (an Android `content://` document) into a
  /// temporary file, so the repository can read it like any other.
  static Future<String> _copyToTemp(PlatformFile file) async {
    final Directory folder = await Directory.systemTemp.createTemp(_tempPrefix);
    final File copy = File('${folder.path}$_separator${file.name}');
    await copy.writeAsBytes(await file.readAsBytes());
    return copy.path;
  }

  @override
  Future<String?> pickExportDirectory() => FilePicker.getDirectoryPath(dialogTitle: _exportDialogTitle);

  @override
  Future<void> triggerExportDownload(String jsonString) async {
    // No-op on mobile/desktop — files are written to disk directly.
  }
}
