import 'dart:io';

import 'package:logger/logger.dart';

import '../../../../core/domain/entities/result.dart';
import '../../domain/entities/recording.dart';
import '../../domain/entities/recording_version.dart';
import '../../domain/repositories/recording_files_repository.dart';
import '../data_sources/system_files_data_source.dart';

/// [RecordingFilesRepository] on the system share sheet and file manager.
final class RecordingFilesRepositoryImpl implements RecordingFilesRepository {
  static const String _shareError = 'Не вдалося надіслати запис';
  static const String _folderError = 'Не вдалося відкрити папку';
  static const String _missingError = 'Файл запису не знайдено';
  static const String _shareLog = 'ShareRecording: failure — ';
  static const String _folderLog = 'ShowRecordingInFolder: failure — ';
  static const String _originalSuffix = ' (оригінал)';
  static const String _extension = '.wav';
  static const String _fallbackName = 'cover';
  static const String _dateSeparator = '-';
  static const String _nameSeparator = ' ';
  static const String _zero = '0';
  static const int _twoDigits = 2;
  static final RegExp _unsafeCharacters = RegExp(r'[\\/:*?"<>|]');

  final SystemFilesDataSource _system;
  final Logger _logger;

  /// Creates a [RecordingFilesRepositoryImpl].
  RecordingFilesRepositoryImpl({required this._system, required this._logger});

  @override
  Future<Result<void>> shareRecording({
    required Recording recording,
    required RecordingVersion version,
    required String? title,
  }) async {
    final String? enhanced = recording.enhancedPath;
    final String path = version == RecordingVersion.enhanced && enhanced != null ? enhanced : recording.rawPath;
    try {
      if (!await File(path).exists()) return const Result.failure(_missingError);
      await _system.shareFile(
        path: path,
        fileName: _fileName(recording, title, isOriginal: path == recording.rawPath),
        text: title,
      );
      return Result.ok;
    } on Exception catch (e) {
      _logger.e('$_shareLog$e');
      return const Result.failure(_shareError);
    }
  }

  @override
  bool canShowInFolder() => _system.canOpenFolder;

  @override
  Future<Result<void>> showInFolder(Recording recording) async {
    try {
      final bool opened = await _system.openFolder(File(recording.rawPath).parent.path);
      return opened ? Result.ok : const Result.failure(_folderError);
    } on Exception catch (e) {
      _logger.e('$_folderLog$e');
      return const Result.failure(_folderError);
    }
  }

  /// `<song> 2026-11-12.wav`, without characters a file system refuses.
  static String _fileName(Recording recording, String? title, {required bool isOriginal}) {
    final DateTime at = recording.recordedAt;
    final String date = <int>[
      at.year,
      at.month,
      at.day,
    ].map((int part) => part.toString().padLeft(_twoDigits, _zero)).join(_dateSeparator);
    final String song = (title ?? _fallbackName).replaceAll(_unsafeCharacters, _nameSeparator).trim();
    return '$song$_nameSeparator$date${isOriginal ? _originalSuffix : ''}$_extension';
  }
}
