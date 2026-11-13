import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:logger/logger.dart';

import '../../../../core/data/data_sources/system_files_data_source.dart';
import '../../../../core/domain/entities/disposable_resource.dart';
import '../../../../core/domain/entities/result.dart';
import '../../../recordings/domain/entities/imported_recording.dart';
import '../../../recordings/domain/entities/recording.dart';
import '../../../recordings/domain/repositories/recordings_repository.dart';
import '../../../song/domain/entities/cover.dart';
import '../../../song/domain/entities/song.dart';
import '../../../song/domain/repositories/song_repository.dart';
import '../../domain/repositories/backup_repository.dart';
import '../data_sources/backup_archive_data_source.dart';
import '../data_sources/backup_data_source.dart';
import '../models/backup_data_model.dart';
import '../models/backup_recording_model.dart';
import '../../../recordings/domain/entities/recordings_failure.dart';
import '../../../song/domain/entities/song_failure.dart';
import '../../domain/entities/backup_failure.dart';

/// Implementation of [BackupRepository] on top of [SongRepository] and [RecordingsRepository].
///
/// Exports the songs to `backup.json`, or — with recordings — to `backup.zip` holding
/// `backup.json` and the WAV files of the recordings. Imports either file; recordings are added
/// to the songs as they were created on this device. File picker operations are encapsulated
/// internally — the interface exposes no file paths.
final class BackupRepositoryImpl implements BackupRepository, DisposableResource {
  static const String _statusIdle = 'idle';
  static const String _jsonIndent = '  ';
  static const String _statusExporting = 'exporting';
  static const String _statusImporting = 'importing';
  static const String _statusSuccess = 'success';
  static const String _statusCancelled = 'cancelled';
  static const String _statusFailed = 'failed';
  static const String _newDocumentId = '';
  static const String _idField = 'id';
  static const String _authorField = 'author';
  static const String _nameField = 'name';
  static const String _albumField = 'album';
  static const String _lyricsField = 'lyrics';
  static const String _coverIdsField = 'coverIds';
  static const String _scrollSpeedField = 'scrollSpeed';
  static const String _leadInField = 'leadIn';
  static const String _jsonFileName = 'backup.json';
  static const String _zipFileName = 'backup.zip';
  static const String _separator = '/';

  static const String _exportStartLog = 'ExportSongs: starting';
  static const String _exportCancelledLog = 'ExportSongs: cancelled by user';
  static const String _exportSuccessLog = 'ExportSongs: success — exported ';
  static const String _exportToFileLog = ' songs to "';
  static const String _exportRecordingsLog = ' recordings and ';
  static const String _exportWebLog = ' songs (web download)';
  static const String _exportFailureLog = 'ExportSongs: failure — ';
  static const String _importStartLog = 'ImportSongs: starting';
  static const String _importCancelledLog = 'ImportSongs: cancelled by user';
  static const String _importSuccessLog = 'ImportSongs: success — ';
  static const String _importedSongsLog = ' songs imported, recordings: ';
  static const String _importFailureLog = 'ImportSongs: failure — ';
  static const String _closingQuoteLog = '"';
  static const String _shareStartLog = 'ShareBackup: starting';
  static const String _shareSuccessLog = 'ShareBackup: success — shared ';
  static const String _shareFailureLog = 'ShareBackup: failure — ';
  static const String _shareFolderPrefix = 'hitwave_backup_';
  static const String _shareFilePrefix = 'hitwave_cover_backup_';
  static const String _jsonExtension = '.json';
  static const String _zipExtension = '.zip';
  static const String _dateSeparator = '-';
  static const String _zero = '0';
  static const int _twoDigits = 2;

  final SongRepository _songRepository;
  final RecordingsRepository _recordingsRepository;
  final BackupDataSource _dataSource;
  final BackupArchiveDataSource _archive;
  final SystemFilesDataSource _system;
  final Logger _logger;

  final ValueNotifier<String> _status = ValueNotifier<String>(_statusIdle);

  /// Creates a new [BackupRepositoryImpl].
  BackupRepositoryImpl({
    required this._songRepository,
    required this._recordingsRepository,
    required this._dataSource,
    required this._archive,
    required this._system,
    required this._logger,
  });

  /// Releases the status state.
  @override
  void dispose() {
    _status.dispose();
  }

  @override
  ValueListenable<String> watchStatus() => _status;

  @override
  Future<Result<void, BackupFailure>> exportSongs({
    required bool includeRecordings,
    required String pickerTitle,
  }) async {
    _logger.i(_exportStartLog);

    try {
      _status.value = _statusExporting;

      final List<Song> songs = _songRepository.watchSongs().value;
      final Set<String> songIds = songs.map(_songId).toSet();
      final List<Recording> recordings = includeRecordings && _dataSource.supportsDirectorySelection
          ? _recordingsRepository
                .watchRecordings()
                .value
                .where((Recording recording) => songIds.contains(recording.songId))
                .toList()
          : const <Recording>[];
      final List<BackupRecordingModel> recordingModels = recordings.map(BackupRecordingModel.fromEntity).toList();

      final BackupDataModel model = BackupDataModel(
        exportedAt: DateTime.now(),
        songs: songs.map(_encodeSong).toList(),
        recordings: recordingModels.map(_encodeRecording).toList(),
      );

      if (_dataSource.supportsDirectorySelection) {
        final String? folder = await _dataSource.pickExportDirectory(pickerTitle);
        if (folder == null) {
          _logger.i(_exportCancelledLog);
          _status.value = _statusCancelled;
          return Result.ok;
        }

        final String filePath;
        if (recordings.isEmpty) {
          filePath = '$folder$_separator$_jsonFileName';
          await _archive.writeJson(path: filePath, json: model.toJson());
        } else {
          filePath = '$folder$_separator$_zipFileName';
          await _archive.writeZip(path: filePath, json: model.toJson(), files: _filesOf(recordings, recordingModels));
        }

        _logger.i(
          '$_exportSuccessLog${recordings.length}$_exportRecordingsLog${songs.length}'
          '$_exportToFileLog$filePath$_closingQuoteLog',
        );
      } else {
        final Map<String, dynamic> jsonMap = jsonDecode(model.toJson()) as Map<String, dynamic>;
        final String jsonString = const JsonEncoder.withIndent(_jsonIndent).convert(jsonMap);
        await _dataSource.triggerExportDownload(jsonString);
        _logger.i('$_exportSuccessLog${songs.length}$_exportWebLog');
      }

      _status.value = _statusSuccess;
      return Result.ok;
    } on Exception catch (e) {
      _logger.e('$_exportFailureLog$e');
      _status.value = _statusFailed;
      return const Result.failure(BackupFailure.exportSongs);
    }
  }

  @override
  Future<Result<void, BackupFailure>> shareBackup({required bool includeRecordings}) async {
    _logger.i(_shareStartLog);
    try {
      _status.value = _statusExporting;
      final List<Song> songs = _songRepository.watchSongs().value;
      final Set<String> songIds = songs.map(_songId).toSet();
      final List<Recording> recordings = includeRecordings
          ? _recordingsRepository
                .watchRecordings()
                .value
                .where((Recording recording) => songIds.contains(recording.songId))
                .toList()
          : const <Recording>[];
      final List<BackupRecordingModel> recordingModels = recordings.map(BackupRecordingModel.fromEntity).toList();
      final BackupDataModel model = BackupDataModel(
        exportedAt: DateTime.now(),
        songs: songs.map(_encodeSong).toList(),
        recordings: recordingModels.map(_encodeRecording).toList(),
      );

      final Directory folder = await Directory.systemTemp.createTemp(_shareFolderPrefix);
      final String name = '$_shareFilePrefix${_date(model.exportedAt)}';
      final String fileName = recordings.isEmpty ? '$name$_jsonExtension' : '$name$_zipExtension';
      final String filePath = '${folder.path}$_separator$fileName';
      if (recordings.isEmpty) {
        await _archive.writeJson(path: filePath, json: model.toJson());
      } else {
        await _archive.writeZip(path: filePath, json: model.toJson(), files: _filesOf(recordings, recordingModels));
      }
      _status.value = _statusSuccess;
      await _system.shareFile(path: filePath, fileName: fileName, text: null);
      _logger.i('$_shareSuccessLog$fileName');
      return Result.ok;
    } on Exception catch (e) {
      _logger.e('$_shareFailureLog$e');
      _status.value = _statusFailed;
      return const Result.failure(BackupFailure.shareBackup);
    }
  }

  /// `2026-11-13` of [time], for the name of a shared backup.
  static String _date(DateTime time) => <int>[
    time.year,
    time.month,
    time.day,
  ].map((int part) => part.toString().padLeft(_twoDigits, _zero)).join(_dateSeparator);

  @override
  Future<Result<void, BackupFailure>> importSongs({required bool includeRecordings}) async {
    _logger.i(_importStartLog);
    String? extractedFolder;

    try {
      _status.value = _statusImporting;

      final PickedBackupFile? file = await _dataSource.pickBackupFile();
      if (file == null) {
        _logger.i(_importCancelledLog);
        _status.value = _statusCancelled;
        return Result.ok;
      }

      final String? path = file.path;
      final Uint8List? bytes = file.bytes;
      final OpenedBackup backup = path != null
          ? await _archive.openFile(path)
          : _archive.openBytes(name: file.name, bytes: bytes ?? Uint8List(0));
      extractedFolder = backup.extractedFolder;
      final BackupDataModel backupDataModel = BackupDataModel.fromJson(backup.json);

      final List<Song> songs = backupDataModel.songs.map(_decodeSong).toList();
      final Result<List<String>, SongFailure> added = await _songRepository.addSongs(songs);
      final List<String> newIds;
      switch (added) {
        case SuccessResult<List<String>, SongFailure>(:final List<String> value):
          newIds = value;
        case FailureResult<List<String>, SongFailure>():
          _status.value = _statusFailed;
          return const Result.failure(BackupFailure.importSongs);
      }

      final List<ImportedRecording> recordings = <ImportedRecording>[];
      final String? folder = extractedFolder;
      if (includeRecordings && folder != null) {
        final Map<String, String> songIds = <String, String>{
          for (int i = 0; i < newIds.length && i < backupDataModel.songs.length; i++)
            backupDataModel.songs[i][_idField] as String: newIds[i],
        };
        for (final Map<String, dynamic> json in backupDataModel.recordings) {
          final BackupRecordingModel model = BackupRecordingModel.fromJson(json);
          final String? songId = songIds[model.songId];
          if (songId != null) recordings.add(model.toEntity(songId: songId, folder: folder));
        }
      }
      if (recordings.isNotEmpty) {
        final Result<void, RecordingsFailure> imported = await _recordingsRepository.importRecordings(recordings);
        if (imported.isFailure) {
          _status.value = _statusFailed;
          return const Result.failure(BackupFailure.importSongs);
        }
      }

      _logger.i('$_importSuccessLog${songs.length}$_importedSongsLog${recordings.length}');
      _status.value = _statusSuccess;
      return Result.ok;
    } on Exception catch (e) {
      _logger.e('$_importFailureLog$e');
      _status.value = _statusFailed;
      return const Result.failure(BackupFailure.importSongs);
    } finally {
      final String? folder = extractedFolder;
      if (folder != null) {
        try {
          await _archive.deleteFolder(folder);
        } on Exception catch (e) {
          _logger.w('$_importFailureLog$e');
        }
      }
    }
  }

  /// Archive name → file on disk of every file of [recordings].
  static Map<String, String> _filesOf(List<Recording> recordings, List<BackupRecordingModel> models) {
    final Map<String, String> files = <String, String>{};
    for (int i = 0; i < recordings.length; i++) {
      files[models[i].rawFile] = recordings[i].rawPath;
      final String? enhancedFile = models[i].enhancedFile;
      final String? enhancedPath = recordings[i].enhancedPath;
      if (enhancedFile != null && enhancedPath != null) files[enhancedFile] = enhancedPath;
    }
    return files;
  }

  static String _songId(Song song) => song.id;

  static Map<String, dynamic> _encodeRecording(BackupRecordingModel model) => model.toJson();

  /// Encodes a song into a JSON-serializable map.
  Map<String, dynamic> _encodeSong(Song song) {
    return <String, dynamic>{
      _idField: song.id,
      _authorField: song.author,
      _nameField: song.name,
      _albumField: song.album,
      _lyricsField: song.lyrics,
      _coverIdsField: song.covers.map(_coverId).toList(),
      _scrollSpeedField: song.scrollSpeed,
      _leadInField: song.leadIn,
    };
  }

  String _coverId(Cover cover) => cover.id;

  /// Decodes a song of a backup file; its covers are not imported.
  Song _decodeSong(Map<String, dynamic> songJson) {
    return Song(
      id: _newDocumentId,
      author: songJson[_authorField] as String,
      name: songJson[_nameField] as String,
      album: songJson[_albumField] as String?,
      lyrics: songJson[_lyricsField] as String,
      covers: const <Cover>[],
      scrollSpeed: (songJson[_scrollSpeedField] as num?)?.toDouble(),
      leadIn: (songJson[_leadInField] as num?)?.toDouble(),
    );
  }
}
