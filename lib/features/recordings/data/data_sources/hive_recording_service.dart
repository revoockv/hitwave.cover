import 'dart:async';
import 'dart:io';

import 'package:hive_ce/hive_ce.dart';
import 'package:path_provider/path_provider.dart';

import '../../../../core/data/data_sources/local_storage_service.dart';
import '../models/recording_model.dart';
import 'mp3_encoder_service.dart';

/// The recordings library on this device: one Hive map per recording plus its WAV files (and the
/// MP3s made from them for sharing) in `<documents>/recordings/` (`<documents>/<storage folder>/recordings/` when
/// [LocalStorageService.storageFolder] is set).
final class HiveRecordingService {
  static const String _boxName = 'recordings';
  static const String _folderName = 'recordings';
  static const String _separator = '/';
  static const String _rawSuffix = '_raw.wav';
  static const String _enhancedSuffix = '_enhanced.wav';

  final LocalStorageService _storage;
  final Future<Directory> Function() _documentsFolder;

  Box<dynamic>? _box;

  String? _folder;

  /// Creates the service; [documentsFolder] is replaced in tests.
  HiveRecordingService({required this._storage, Future<Directory> Function()? documentsFolder})
    : _documentsFolder = documentsFolder ?? getApplicationDocumentsDirectory;

  /// Opens the box and creates the folder; returns this for `registerSingletonAsync`.
  Future<HiveRecordingService> init() async {
    _box = await _storage.openBox(_boxName);
    final Directory documents = await _documentsFolder();
    final String storage = LocalStorageService.storageFolder.isEmpty
        ? documents.path
        : '${documents.path}$_separator${LocalStorageService.storageFolder}';
    final Directory folder = await Directory('$storage$_separator$_folderName').create(recursive: true);
    _folder = folder.path;
    return this;
  }

  Box<dynamic> get _recordings => _box!;

  /// Full path of the folder of the WAV files.
  String get folder => _folder!;

  /// File name of the raw take of [id].
  String rawFileOf(String id) => '$id$_rawSuffix';

  /// File name of the enhanced take of [id].
  String enhancedFileOf(String id) => '$id$_enhancedSuffix';

  /// Full path of the raw take of [id].
  String rawPathOf(String id) => '$folder$_separator${rawFileOf(id)}';

  /// Full path of the enhanced take of [id].
  String enhancedPathOf(String id) => '$folder$_separator${enhancedFileOf(id)}';

  /// Every stored recording.
  List<RecordingModel> readAll() => _recordings.values.map(_toModel).toList();

  /// Stores [model], replacing the one with its id.
  Future<void> put(RecordingModel model) => _recordings.put(model.id, model.toMap());

  /// Deletes the recording [id] and its files.
  Future<void> delete(String id) async {
    await _recordings.delete(id);
    for (final String path in <String>[
      rawPathOf(id),
      enhancedPathOf(id),
      Mp3EncoderService.mp3PathOf(rawPathOf(id)),
      Mp3EncoderService.mp3PathOf(enhancedPathOf(id)),
    ]) {
      final File file = File(path);
      if (await file.exists()) await file.delete();
    }
  }

  /// Moves the file at [from] to [to] (copies when they are on different volumes).
  Future<void> moveFile({required String from, required String to}) async {
    final File source = File(from);
    try {
      await source.rename(to);
    } on FileSystemException {
      await source.copy(to);
      await source.delete();
    }
  }

  RecordingModel _toModel(dynamic value) => RecordingModel.fromMap(value as Map<dynamic, dynamic>);
}
