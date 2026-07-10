import 'dart:convert';
import 'package:universal_html/html.dart' as html;
import 'package:file_picker/file_picker.dart';

import 'backup_data_source.dart';

/// Web implementation of [BackupDataSource] using `file_picker` with
/// browser-compatible file handling.
///
/// On web, `dart:io` is unavailable, so we read file bytes from the
/// `file_picker` result and decode them as UTF-8. For export, we return
/// `null` since the repository handles browser downloads directly.
final class BackupDataSourceWeb implements BackupDataSource {
  static const List<String> _allowedExtensions = ['json'];
  static const String _backupFileName = 'backup.json';

  @override
  bool get supportsDirectorySelection => false;

  @override
  Future<String?> pickBackupFile() async {
    try {
      final FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: _allowedExtensions,
        allowMultiple: false,
      );

      if (result == null || result.files.isEmpty) {
        return null;
      }

      final bytes = result.files.single.bytes;
      if (bytes != null) {
        return utf8.decode(bytes);
      }

      return null;
    } catch (e) {
      return null;
    }
  }

  @override
  Future<String?> pickExportDirectory() async {
    return null;
  }

  @override
  Future<void> triggerExportDownload(String jsonString) async {
// --- WEB ARCHITECTURE ---
    // universal_html lets this compile on Android without breaking!
    final blob = html.Blob([jsonString]);
    final url = html.Url.createObjectUrlFromBlob(blob);

    final anchor = html.document.createElement('a') as html.AnchorElement;
    anchor.href = url;
    anchor.download = _backupFileName;
    anchor.click();

    html.Url.revokeObjectUrl(url); }
}
