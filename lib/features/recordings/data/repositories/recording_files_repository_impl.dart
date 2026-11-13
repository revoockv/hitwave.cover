import 'dart:io';

import 'package:logger/logger.dart';

import '../../../../core/domain/entities/result.dart';
import '../../domain/entities/recording.dart';
import '../../domain/entities/recording_version.dart';
import '../../domain/entities/shared_song.dart';
import '../../domain/repositories/recording_files_repository.dart';
import '../data_sources/system_files_data_source.dart';

/// [RecordingFilesRepository] on the system share sheet and file manager.
final class RecordingFilesRepositoryImpl implements RecordingFilesRepository {
  static const String _shareError = 'Не вдалося надіслати запис';
  static const String _folderError = 'Не вдалося відкрити папку';
  static const String _missingError = 'Файл запису не знайдено';
  static const String _shareLog = 'ShareRecording: failure — ';
  static const String _folderLog = 'ShowRecordingInFolder: failure — ';
  static const String _extension = '.wav';
  static const String _fallbackName = 'cover';
  static const String _fileSeparator = '-';
  static const String _messageSeparator = ' - ';
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
  Future<Result<bool>> shareRecording({
    required Recording recording,
    required RecordingVersion version,
    required SharedSong? song,
  }) async {
    final String? enhanced = recording.enhancedPath;
    final String path = version == RecordingVersion.enhanced && enhanced != null ? enhanced : recording.rawPath;
    try {
      if (!await File(path).exists()) return const Result.failure(_missingError);
      return Result.success(
        await _system.shareFile(path: path, fileName: fileName(recording, song), text: message(song)),
      );
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

  /// The text sent with the file: `Artist - Song`, or `null` when the song is unknown.
  static String? message(SharedSong? song) =>
      song == null ? null : '${song.author.trim()}$_messageSeparator${song.name.trim()}';

  /// `2026-11-12-19-05 Artist-Song.wav` (recording time, 24 h), without characters a file system
  /// refuses.
  static String fileName(Recording recording, SharedSong? song) {
    final String? title = song == null ? null : '${song.author.trim()}$_fileSeparator${song.name.trim()}';
    final DateTime at = recording.recordedAt;
    final String time = <int>[
      at.year,
      at.month,
      at.day,
      at.hour,
      at.minute,
    ].map((int part) => part.toString().padLeft(_twoDigits, _zero)).join(_dateSeparator);
    final String stem = (title ?? _fallbackName).replaceAll(_unsafeCharacters, _nameSeparator).trim();
    return '$time$_nameSeparator$stem$_extension';
  }
}
