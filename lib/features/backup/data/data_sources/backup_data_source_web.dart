import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:universal_html/html.dart' as html;

import 'backup_data_source.dart';

/// Web implementation of [BackupDataSource] using `file_picker` with
/// browser-compatible file handling.
///
/// On web, `dart:io` is unavailable, so the picked file comes back as bytes. For export, the
/// repository triggers a browser download directly.
final class BackupDataSourceWeb implements BackupDataSource {
  static const List<String> _allowedExtensions = <String>['json', 'zip'];
  static const String _backupFileName = 'backup.json';
  static const String _anchorTag = 'a';

  @override
  bool get supportsDirectorySelection => false;

  @override
  Future<PickedBackupFile?> pickBackupFile() async {
    final PlatformFile? file = await FilePicker.pickFile(type: FileType.custom, allowedExtensions: _allowedExtensions);
    if (file == null) {
      return null;
    }
    final Uint8List bytes = await file.readAsBytes();
    return PickedBackupFile(name: file.name, path: null, bytes: bytes);
  }

  @override
  Future<String?> pickExportDirectory(String title) async {
    return null;
  }

  @override
  Future<void> triggerExportDownload(String jsonString) async {
    // universal_html lets this compile on Android without breaking.
    final blob = html.Blob([jsonString]);
    final url = html.Url.createObjectUrlFromBlob(blob);

    final anchor = html.document.createElement(_anchorTag) as html.AnchorElement;
    anchor.href = url;
    anchor.download = _backupFileName;
    anchor.click();

    html.Url.revokeObjectUrl(url);
  }
}
