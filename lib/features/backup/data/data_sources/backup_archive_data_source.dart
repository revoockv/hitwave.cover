import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:archive/archive_io.dart';

/// The content of a backup: the JSON, and — for a ZIP read from disk — the folder its other
/// files were extracted into.
final class OpenedBackup {
  /// The `backup.json` text.
  final String json;

  /// Folder of the extracted files (archive names are relative to it); `null` when nothing was
  /// extracted. The caller deletes it when done.
  final String? extractedFolder;

  /// Creates an [OpenedBackup].
  const OpenedBackup({required this.json, required this.extractedFolder});
}

/// Writes and reads backup files: plain `backup.json`, or `backup.zip` with `backup.json` and the
/// recordings. ZIP files are streamed from and to disk, so long recordings never sit in memory.
final class BackupArchiveDataSource {
  /// Name of the JSON file of a backup, also inside a ZIP.
  static const String jsonName = 'backup.json';
  static const String _zipExtension = '.zip';
  static const String _tempPrefix = 'hitwave_backup_';
  static const String _separator = '/';
  static const String _noJsonError = 'The archive has no backup.json';

  /// Writes [json] to the file at [path].
  Future<void> writeJson({required String path, required String json}) => File(path).writeAsString(json);

  /// Writes a ZIP at [path] with [json] as `backup.json` and every file of [files]
  /// (archive name → file on disk).
  Future<void> writeZip({required String path, required String json, required Map<String, String> files}) async {
    final ZipFileEncoder encoder = ZipFileEncoder()..create(path);
    try {
      encoder.addArchiveFile(ArchiveFile.string(jsonName, json));
      for (final MapEntry<String, String> file in files.entries) {
        await encoder.addFile(File(file.value), file.key);
      }
    } finally {
      await encoder.close();
    }
  }

  /// Whether the file called [name] is a ZIP backup.
  bool isZip(String name) => name.toLowerCase().endsWith(_zipExtension);

  /// Opens the backup at [path]: a JSON file is read; a ZIP is extracted to a temporary folder.
  Future<OpenedBackup> openFile(String path) async {
    if (!isZip(path)) {
      return OpenedBackup(json: await File(path).readAsString(), extractedFolder: null);
    }
    final Directory folder = await Directory.systemTemp.createTemp(_tempPrefix);
    final InputFileStream input = InputFileStream(path);
    try {
      final Archive archive = ZipDecoder().decodeStream(input);
      await extractArchiveToDisk(archive, folder.path);
    } finally {
      await input.close();
    }
    final File json = File('${folder.path}$_separator$jsonName');
    if (!await json.exists()) {
      await folder.delete(recursive: true);
      throw const FormatException(_noJsonError);
    }
    return OpenedBackup(json: await json.readAsString(), extractedFolder: folder.path);
  }

  /// Opens a backup given as [bytes] (web): only its JSON is read, recordings are skipped.
  OpenedBackup openBytes({required String name, required Uint8List bytes}) {
    if (!isZip(name)) {
      return OpenedBackup(json: utf8.decode(bytes), extractedFolder: null);
    }
    final ArchiveFile? json = ZipDecoder().decodeBytes(bytes).findFile(jsonName);
    final Uint8List? content = json?.readBytes();
    if (content == null) throw const FormatException(_noJsonError);
    return OpenedBackup(json: utf8.decode(content), extractedFolder: null);
  }

  /// Deletes a folder made by [openFile].
  Future<void> deleteFolder(String folder) => Directory(folder).delete(recursive: true);
}
