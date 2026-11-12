import 'package:file_picker/file_picker.dart';

import 'backup_data_source.dart';

/// [BackupDataSource] of the platforms with a file system (mobile and desktop).
///
/// Picks a backup file for import (its path is returned, the repository reads it) and a
/// directory for export.
final class BackupDataSourceMobile implements BackupDataSource {
  static const List<String> _allowedExtensions = <String>['json', 'zip'];
  static const String _exportDialogTitle = 'Оберіть папку для експорту';

  @override
  bool get supportsDirectorySelection => true;

  @override
  Future<PickedBackupFile?> pickBackupFile() async {
    final FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: _allowedExtensions,
      allowMultiple: false,
    );
    final PlatformFile? file = result?.files.single;
    final String? path = file?.path;
    if (file == null || path == null) {
      return null;
    }
    return PickedBackupFile(name: file.name, path: path, bytes: null);
  }

  @override
  Future<String?> pickExportDirectory() => FilePicker.platform.getDirectoryPath(dialogTitle: _exportDialogTitle);

  @override
  Future<void> triggerExportDownload(String jsonString) async {
    // No-op on mobile/desktop — files are written to disk directly.
  }
}
