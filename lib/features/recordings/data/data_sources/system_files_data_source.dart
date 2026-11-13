import 'dart:io';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

/// The system share sheet and the file manager.
final class SystemFilesDataSource {
  /// Opens the share sheet with the file at [path], named [fileName], and [text].
  Future<void> shareFile({required String path, required String fileName, required String? text}) async {
    await SharePlus.instance.share(
      ShareParams(
        files: <XFile>[XFile(path, name: fileName)],
        fileNameOverrides: <String>[fileName],
        text: text,
      ),
    );
  }

  /// Whether a folder can be opened in the file manager (desktop).
  bool get canOpenFolder => !kIsWeb && (Platform.isMacOS || Platform.isWindows || Platform.isLinux);

  /// Opens [folder] in the file manager; `false` when the system refused.
  Future<bool> openFolder(String folder) => launchUrl(Uri.directory(folder));
}
