import 'dart:io';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/services.dart' show MethodChannel;
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

/// The system share sheet and the file manager.
final class SystemFilesDataSource {
  static const String _shareFolderPrefix = 'hitwave_share_';
  static const String _separator = '/';
  static const MethodChannel _macosShare = MethodChannel('hitwave/share');
  static const String _shareFileMethod = 'shareFile';
  static const String _pathArgument = 'path';
  static const String _textArgument = 'text';

  /// The folder of the copy shared last; deleted at the next share.
  Directory? _lastShareFolder;

  /// Opens the share sheet with the file at [path], named [fileName], and [text].
  ///
  /// The share sheet of some systems (macOS) takes the name of the file on disk, so a copy with
  /// [fileName] is shared from a temporary folder. On macOS the share_plus plugin drops the text
  /// when it shares a file, so the app's own channel (MainFlutterWindow.swift) shares both.
  Future<void> shareFile({required String path, required String fileName, required String? text}) async {
    await _deleteLastCopy();
    final Directory folder = await Directory.systemTemp.createTemp(_shareFolderPrefix);
    _lastShareFolder = folder;
    final File copy = await File(path).copy('${folder.path}$_separator$fileName');
    if (!kIsWeb && Platform.isMacOS) {
      await _macosShare.invokeMethod<void>(_shareFileMethod, <String, String?>{
        _pathArgument: copy.path,
        _textArgument: text,
      });
      return;
    }
    await SharePlus.instance.share(
      ShareParams(
        files: <XFile>[XFile(copy.path, name: fileName)],
        fileNameOverrides: <String>[fileName],
        text: text,
      ),
    );
  }

  /// Whether a folder can be opened in the file manager (desktop).
  bool get canOpenFolder => !kIsWeb && (Platform.isMacOS || Platform.isWindows || Platform.isLinux);

  /// Opens [folder] in the file manager; `false` when the system refused.
  Future<bool> openFolder(String folder) => launchUrl(Uri.directory(folder));

  /// Deletes the copy shared last; the receiving app has taken it by now.
  Future<void> _deleteLastCopy() async {
    final Directory? folder = _lastShareFolder;
    _lastShareFolder = null;
    try {
      if (folder != null && await folder.exists()) await folder.delete(recursive: true);
    } on FileSystemException {
      // A temporary folder the system cleans up anyway.
    }
  }
}
