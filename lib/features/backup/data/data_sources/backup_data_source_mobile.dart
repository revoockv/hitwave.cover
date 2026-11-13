import 'dart:io';

import 'package:file_picker/file_picker.dart';

import 'backup_data_source.dart';

/// Platform-agnostic implementation of [BackupDataSource] using
/// `file_picker` and `path_provider` packages.
///
/// Handles file selection for import (picks a JSON file and reads its content)
/// and directory selection for export (picks a directory path).
final class BackupDataSourceMobile implements BackupDataSource {
  static const String _backupFileName = 'backup.json';
  static const List<String> _allowedExtensions = ['json'];
  static const String _pathSeparator = '/';
  static const String _exportDialogTitle = 'Оберіть папку для експорту';

  @override
  bool get supportsDirectorySelection => true;

  @override
  Future<String?> pickBackupFile() async {
    try {
      final FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: _allowedExtensions,
        allowMultiple: false,
      );

      if (result?.files.single.path == null) {
        return null;
      }

      final String filePath = result!.files.single.path!;
      final String content = await File(filePath).readAsString();
      return content;
    } catch (e) {
      return null;
    }
  }

  @override
  Future<String?> pickExportDirectory() async {
    try {
      final String? directoryPath = await FilePicker.platform.getDirectoryPath(
        dialogTitle: _exportDialogTitle,
      );

      if (directoryPath == null) {
        return null;
      }

      return '$directoryPath$_pathSeparator$_backupFileName';
    } catch (e) {
      return null;
    }
  }

  @override
  Future<void> triggerExportDownload(String jsonString) async {
    // No-op on mobile/desktop — files are written to disk directly.
  }
}
