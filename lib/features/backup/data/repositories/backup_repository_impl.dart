import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:logger/logger.dart';

import '../../../../core/data/data_sources/system_files_data_source.dart';
import '../../../../core/domain/entities/disposable_resource.dart';
import '../../../../core/domain/entities/result.dart';
import '../../../recordings/domain/entities/imported_recording.dart';
import '../../../recordings/domain/entities/recording.dart';
import '../../../recordings/domain/repositories/recordings_repository.dart';
import '../../../song/domain/entities/song.dart';
import '../../../song/domain/repositories/song_repository.dart';
import '../../domain/repositories/backup_repository.dart';
import '../data_sources/backup_archive_data_source.dart';
import '../data_sources/backup_data_source.dart';
import '../models/backup_data_model.dart';
import '../models/backup_recording_model.dart';
import '../models/backup_song_model.dart';
import '../../../recordings/domain/entities/recordings_failure.dart';
import '../../../song/domain/entities/song_failure.dart';
import '../../domain/entities/backup_failure.dart';
import '../../domain/entities/import_choice.dart';
import '../../domain/entities/import_decision.dart';
import '../../domain/entities/import_conflict.dart';
import '../../domain/entities/import_plan.dart';
import '../../domain/entities/import_summary.dart';
import '../../../song/domain/entities/lyrics_layout.dart';

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
  static const String _jsonFileName = 'backup.json';
  static const String _zipFileName = 'backup.zip';
  static const String _separator = '/';
  static const String _keySeparator = '\u0000';
  static const String _copyOpen = ' (';
  static const String _copyClose = ')';
  static const int _firstCopyNumber = 2;

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

  /// The backup opened by [openImport], until it is imported or dropped.
  _PendingImport? _pending;

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
    final String? folder = _pending?.extractedFolder;
    if (folder != null) unawaited(_deleteFolder(folder));
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
        songs: songs.map(BackupSongModel.fromEntity).toList(),
        recordings: recordingModels,
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
        await _dataSource.triggerExportDownload(model.toJson(indent: _jsonIndent));
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
        songs: songs.map(BackupSongModel.fromEntity).toList(),
        recordings: recordingModels,
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
  Future<Result<ImportPlan?, BackupFailure>> openImport({required bool includeRecordings}) async {
    _logger.i(_importStartLog);
    await cancelImport();
    String? extractedFolder;
    try {
      _status.value = _statusImporting;

      final PickedBackupFile? file = await _dataSource.pickBackupFile();
      if (file == null) {
        _logger.i(_importCancelledLog);
        _status.value = _statusCancelled;
        return const Result.success(null);
      }

      final String? path = file.path;
      final Uint8List? bytes = file.bytes;
      final OpenedBackup backup = path != null
          ? await _archive.openFile(path)
          : _archive.openBytes(name: file.name, bytes: bytes ?? Uint8List(0));
      extractedFolder = backup.extractedFolder;
      final BackupDataModel model = BackupDataModel.fromJson(backup.json);

      final Map<String, Song> library = <String, Song>{};
      for (final Song song in _songRepository.watchSongs().value) {
        library.putIfAbsent(_keyOf(song.author, song.name), () => song);
      }
      final Map<int, String> existingIds = <int, String>{};
      final List<ImportConflict> conflicts = <ImportConflict>[];
      for (int i = 0; i < model.songs.length; i++) {
        final Song song = model.songs[i].toImportedSong(id: _newDocumentId);
        final Song? existing = library[_keyOf(song.author, song.name)];
        if (existing == null) continue;
        existingIds[i] = existing.id;
        conflicts.add(
          ImportConflict(
            index: i,
            author: song.author,
            name: song.name,
            hasSameLyrics: existing.lyrics.trim() == song.lyrics.trim(),
          ),
        );
      }

      _pending = _PendingImport(
        model: model,
        folder: includeRecordings ? extractedFolder : null,
        extractedFolder: extractedFolder,
        existingIds: existingIds,
      );
      extractedFolder = null;
      return Result.success(ImportPlan(songCount: model.songs.length, conflicts: conflicts));
    } on Exception catch (e) {
      _logger.e('$_importFailureLog$e');
      _status.value = _statusFailed;
      return const Result.failure(BackupFailure.importSongs);
    } finally {
      final String? folder = extractedFolder;
      if (folder != null) await _deleteFolder(folder);
    }
  }

  @override
  Future<Result<ImportSummary, BackupFailure>> applyImport(List<ImportDecision> decisions) async {
    final _PendingImport? pending = _pending;
    _pending = null;
    if (pending == null) return const Result.failure(BackupFailure.importSongs);

    try {
      _status.value = _statusImporting;
      final BackupDataModel model = pending.model;
      final Set<String> taken = <String>{
        for (final Song song in _songRepository.watchSongs().value) _keyOf(song.author, song.name),
      };
      final Map<int, ImportChoice> choices = <int, ImportChoice>{
        for (final ImportDecision decision in decisions) decision.index: decision.choice,
      };
      final Map<String, String> targetIds = <String, String>{};
      final Set<String> replacedIds = <String>{};
      final List<String> addedBackupIds = <String>[];
      final List<Song> added = <Song>[];
      int skipped = 0;

      for (int i = 0; i < model.songs.length; i++) {
        final BackupSongModel backupSong = model.songs[i];
        final String backupId = backupSong.id;
        final String? existingId = pending.existingIds[i];
        if (existingId == null) {
          addedBackupIds.add(backupId);
          added.add(backupSong.toImportedSong(id: _newDocumentId));
          continue;
        }
        switch (choices[i] ?? ImportChoice.skip) {
          case ImportChoice.replace:
            if (!await _replace(existingId, backupSong.toImportedSong(id: _newDocumentId))) {
              _status.value = _statusFailed;
              return const Result.failure(BackupFailure.importSongs);
            }
            targetIds[backupId] = existingId;
            replacedIds.add(existingId);
          case ImportChoice.keepBoth:
            final Song song = backupSong.toImportedSong(id: _newDocumentId);
            final String name = _freeName(song.author, song.name, taken);
            taken.add(_keyOf(song.author, name));
            addedBackupIds.add(backupId);
            added.add(backupSong.toImportedSong(id: _newDocumentId, name: name));
          case ImportChoice.skip:
            skipped++;
        }
      }

      final Result<List<String>, SongFailure> result = await _songRepository.addSongs(added);
      switch (result) {
        case SuccessResult<List<String>, SongFailure>(:final List<String> value):
          for (int i = 0; i < value.length && i < addedBackupIds.length; i++) {
            targetIds[addedBackupIds[i]] = value[i];
          }
        case FailureResult<List<String>, SongFailure>():
          _status.value = _statusFailed;
          return const Result.failure(BackupFailure.importSongs);
      }

      final List<ImportedRecording> recordings = _recordingsOf(pending, targetIds, replacedIds);
      if (recordings.isNotEmpty) {
        final Result<void, RecordingsFailure> imported = await _recordingsRepository.importRecordings(recordings);
        if (imported.isFailure) {
          _status.value = _statusFailed;
          return const Result.failure(BackupFailure.importSongs);
        }
      }

      _logger.i('$_importSuccessLog${added.length}$_importedSongsLog${recordings.length}');
      _status.value = _statusSuccess;
      return Result.success(ImportSummary(added: added.length, replaced: replacedIds.length, skipped: skipped));
    } on Exception catch (e) {
      _logger.e('$_importFailureLog$e');
      _status.value = _statusFailed;
      return const Result.failure(BackupFailure.importSongs);
    } finally {
      final String? folder = pending.extractedFolder;
      if (folder != null) await _deleteFolder(folder);
    }
  }

  @override
  Future<void> cancelImport() async {
    final _PendingImport? pending = _pending;
    _pending = null;
    if (pending == null) return;
    _logger.i(_importCancelledLog);
    _status.value = _statusCancelled;
    final String? folder = pending.extractedFolder;
    if (folder != null) await _deleteFolder(folder);
  }

  /// Gives the song [songId] of the library the lyrics, album and speeds of [song]; its covers
  /// and takes stay. Whether it worked.
  Future<bool> _replace(String songId, Song song) async {
    final List<Future<Result<void, SongFailure>>> updates = <Future<Result<void, SongFailure>>>[
      _songRepository.updateSong(
        songId: songId,
        author: song.author,
        name: song.name,
        album: song.album,
        lyrics: song.lyrics,
      ),
      for (final LyricsLayout layout in LyricsLayout.values) ...<Future<Result<void, SongFailure>>>[
        if (_ownSpeedOf(song, layout) case final double speed)
          _songRepository.updateSongScrollSpeed(songId: songId, layout: layout, speed: speed),
        if (_ownLeadInOf(song, layout) case final double leadIn)
          _songRepository.updateSongLeadIn(songId: songId, layout: layout, leadIn: leadIn),
      ],
    ];
    for (final Future<Result<void, SongFailure>> update in updates) {
      if ((await update).isFailure) return false;
    }
    return true;
  }

  static double? _ownSpeedOf(Song song, LyricsLayout layout) => switch (layout) {
    LyricsLayout.compact => song.scrollSpeed,
    LyricsLayout.wide => song.wideScrollSpeed,
  };

  static double? _ownLeadInOf(Song song, LyricsLayout layout) => switch (layout) {
    LyricsLayout.compact => song.leadIn,
    LyricsLayout.wide => song.wideLeadIn,
  };

  /// The takes of [pending] for the songs imported into [targetIds] (backup id → id here); a take
  /// of a replaced song that is already there (same time) is left out.
  List<ImportedRecording> _recordingsOf(
    _PendingImport pending,
    Map<String, String> targetIds,
    Set<String> replacedIds,
  ) {
    final String? folder = pending.folder;
    if (folder == null) return const <ImportedRecording>[];
    final Set<String> present = <String>{
      for (final Recording recording in _recordingsRepository.watchRecordings().value)
        if (replacedIds.contains(recording.songId)) _takeKey(recording.songId, recording.recordedAt),
    };
    final List<ImportedRecording> recordings = <ImportedRecording>[];
    for (final BackupRecordingModel model in pending.model.recordings) {
      final String? songId = targetIds[model.songId];
      if (songId == null || present.contains(_takeKey(songId, model.recordedAt))) continue;
      recordings.add(model.toEntity(songId: songId, folder: folder));
    }
    return recordings;
  }

  static String _takeKey(String songId, DateTime recordedAt) => '$songId$_keySeparator${recordedAt.toIso8601String()}';

  /// Author and name of a song as they are compared: trimmed, case ignored.
  static String _keyOf(String author, String name) =>
      '${author.trim().toLowerCase()}$_keySeparator${name.trim().toLowerCase()}';

  /// `name (2)`, `name (3)`… — the first one [taken] has not for [author].
  static String _freeName(String author, String name, Set<String> taken) {
    for (int n = _firstCopyNumber; ; n++) {
      final String candidate = '$name$_copyOpen$n$_copyClose';
      if (!taken.contains(_keyOf(author, candidate))) return candidate;
    }
  }

  Future<void> _deleteFolder(String folder) async {
    try {
      await _archive.deleteFolder(folder);
    } on Exception catch (e) {
      _logger.w('$_importFailureLog$e');
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
}

/// A backup read by [BackupRepositoryImpl.openImport] and waiting to be imported.
final class _PendingImport {
  /// The backup.
  final BackupDataModel model;

  /// Folder of the takes to import; `null` when takes are not imported.
  final String? folder;

  /// Folder the ZIP was extracted into, deleted when the import ends.
  final String? extractedFolder;

  /// Position in the backup → id of the song with the same author and name in the library.
  final Map<int, String> existingIds;

  const _PendingImport({
    required this.model,
    required this.folder,
    required this.extractedFolder,
    required this.existingIds,
  });
}
