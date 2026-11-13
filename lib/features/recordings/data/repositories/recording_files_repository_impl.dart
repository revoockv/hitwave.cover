import 'dart:io';

import 'package:logger/logger.dart';
import 'package:path_provider/path_provider.dart';

import '../../../../core/domain/entities/result.dart';
import '../../domain/entities/recording.dart';
import '../../domain/entities/recording_version.dart';
import '../../domain/entities/shared_song.dart';
import '../../domain/repositories/recording_files_repository.dart';
import '../data_sources/mp3_encoder_service.dart';
import '../data_sources/system_files_data_source.dart';

/// [RecordingFilesRepository] on the system share sheet, the file manager and an MP3 encoder.
///
/// A cover is shared as MP3 (the library keeps WAV): the MP3 is made once and kept in the cache
/// folder, named after the recording, the version and the size of the WAV, so a take enhanced
/// again gets a new one.
final class RecordingFilesRepositoryImpl implements RecordingFilesRepository {
  static const String _shareError = 'Не вдалося надіслати запис';
  static const String _folderError = 'Не вдалося відкрити папку';
  static const String _missingError = 'Файл запису не знайдено';
  static const String _shareLog = 'ShareRecording: failure — ';
  static const String _folderLog = 'ShowRecordingInFolder: failure — ';
  static const String _extension = '.mp3';
  static const String _cacheFolderName = 'shared_mp3';
  static const String _cacheSeparator = '_';
  static const String _folderSeparator = '/';
  static const String _encodeLog = 'EncodeMp3: ';
  static const String _successLog = 'success — ';
  static const String _millisecondsLog = ' ms';
  static const String _fallbackName = 'cover';
  static const String _fileSeparator = '-';
  static const String _messageSeparator = ' - ';
  static const String _dateSeparator = '-';
  static const String _nameSeparator = ' ';
  static const String _zero = '0';
  static const int _twoDigits = 2;
  static final RegExp _unsafeCharacters = RegExp(r'[\\/:*?"<>|]');

  final SystemFilesDataSource _system;
  final Mp3EncoderService _encoder;
  final Logger _logger;
  final Future<Directory> Function() _cacheFolder;

  /// Creates a [RecordingFilesRepositoryImpl].
  RecordingFilesRepositoryImpl({
    required this._system,
    required this._encoder,
    required this._logger,
    Future<Directory> Function()? cacheFolder,
  }) : _cacheFolder = cacheFolder ?? getApplicationCacheDirectory;

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
      final String mp3 = await _mp3Of(recording, version, path);
      return Result.success(
        await _system.shareFile(path: mp3, fileName: fileName(recording, song), text: message(song)),
      );
    } on Exception catch (e) {
      _logger.e('$_shareLog$e');
      return const Result.failure(_shareError);
    }
  }

  /// The MP3 of the [version] of [recording] (WAV at [wavPath]), made now when not in the cache.
  Future<String> _mp3Of(Recording recording, RecordingVersion version, String wavPath) async {
    final Directory folder = await Directory(
      '${(await _cacheFolder()).path}$_folderSeparator$_cacheFolderName',
    ).create(recursive: true);
    final String prefix = '${recording.id}$_cacheSeparator${version.name}$_cacheSeparator';
    final File mp3 = File('${folder.path}$_folderSeparator$prefix${await File(wavPath).length()}$_extension');
    if (await mp3.exists()) return mp3.path;
    await for (final FileSystemEntity old in folder.list()) {
      if (old is File && old.uri.pathSegments.last.startsWith(prefix)) await old.delete();
    }
    final Stopwatch stopwatch = Stopwatch()..start();
    await _encoder.encode(wavPath: wavPath, mp3Path: mp3.path);
    _logger.i('$_encodeLog$_successLog${recording.id} ${stopwatch.elapsedMilliseconds}$_millisecondsLog');
    return mp3.path;
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

  /// `2026-11-12-19-05 Artist-Song.mp3` (recording time, 24 h), without characters a file system
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
