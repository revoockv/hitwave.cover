import 'dart:convert';
import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:flutter/foundation.dart';
import 'package:logger/logger.dart';

import '../../../../core/domain/entities/disposable_resource.dart';
import '../../../../core/domain/entities/result.dart';
import '../../../song/data/data_sources/firebase_song_service.dart';
import '../../../song/data/models/song_model.dart';
import '../../../song/domain/entities/cover.dart';
import '../../../song/domain/entities/song.dart';
import '../../../song/domain/repositories/song_repository.dart';
import '../../domain/repositories/backup_repository.dart';
import '../data_sources/backup_data_source.dart';
import '../models/backup_data_model.dart';

/// Firebase-based implementation of [BackupRepository].
///
/// Handles exporting songs to JSON files and importing songs from JSON files,
/// persisting them to Firebase. File picker operations are encapsulated
/// internally — the interface exposes no file paths.
final class BackupRepositoryImpl implements BackupRepository, DisposableResource {
  static const String _statusIdle = 'idle';
  static const String _jsonIndent = '  ';
  static const String _statusExporting = 'exporting';
  static const String _statusImporting = 'importing';
  static const String _statusSuccess = 'success';
  static const String _statusUnauthorizedError = 'Помилка: користувач не авторизований';
  static const String _userNotAuthenticated = 'Користувач не авторизований.';
  static const String _pickerCancelled = 'Вибір скасовано';
  static const String _exportFailedMessage = 'Помилка при експорті.';
  static const String _importFailedMessage = 'Помилка при імпорті.';
  static const String _newDocumentId = '';
  static const String _idField = 'id';
  static const String _authorField = 'author';
  static const String _nameField = 'name';
  static const String _albumField = 'album';
  static const String _lyricsField = 'lyrics';
  static const String _coverIdsField = 'coverIds';

  static const String _exportStartLog = 'ExportSongs: starting';
  static const String _exportNotAuthenticatedLog = 'ExportSongs: failed — user is not authenticated';
  static const String _exportCancelledLog = 'ExportSongs: cancelled by user';
  static const String _exportSuccessLog = 'ExportSongs: success — exported ';
  static const String _exportToFileLog = ' songs to "';
  static const String _exportWebLog = ' songs (web download)';
  static const String _exportFailureLog = 'ExportSongs: failure — ';
  static const String _importStartLog = 'ImportSongs: starting';
  static const String _importNotAuthenticatedLog = 'ImportSongs: failed — user is not authenticated';
  static const String _importCancelledLog = 'ImportSongs: cancelled by user';
  static const String _importSuccessLog = 'ImportSongs: success — ';
  static const String _importedSongsLog = ' songs imported';
  static const String _importFailureLog = 'ImportSongs: failure — ';
  static const String _closingQuoteLog = '"';

  final FirebaseSongService _songService;
  final SongRepository _songRepository;
  final BackupDataSource _dataSource;
  final firebase_auth.FirebaseAuth _auth;
  final Logger _logger;

  final ValueNotifier<String> _status = ValueNotifier<String>(_statusIdle);

  /// Creates a new [BackupRepositoryImpl].
  BackupRepositoryImpl({
    required this._songService,
    required this._songRepository,
    required this._dataSource,
    required this._auth,
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
  Future<Result<void>> exportSongs() async {
    _logger.i(_exportStartLog);

    final String? userId = _auth.currentUser?.uid;
    if (userId == null) {
      _logger.w(_exportNotAuthenticatedLog);
      _status.value = _statusUnauthorizedError;
      return const Result.failure(_userNotAuthenticated);
    }

    try {
      _status.value = _statusExporting;

      final List<Song> songs = _songRepository.watchSongs().value;

      final BackupDataModel model = BackupDataModel(
        exportedAt: DateTime.now(),
        songs: songs.map(_encodeSong).toList(),
      );

      if (_dataSource.supportsDirectorySelection) {
        final String? filePath = await _dataSource.pickExportDirectory();
        if (filePath == null) {
          _logger.i(_exportCancelledLog);
          _status.value = _pickerCancelled;
          return Result.ok;
        }

        await File(filePath).writeAsString(model.toJson());

        _logger.i('$_exportSuccessLog${songs.length}$_exportToFileLog$filePath$_closingQuoteLog');
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
      _status.value = _exportFailedMessage;
      return const Result.failure(_exportFailedMessage);
    }
  }

  @override
  Future<Result<void>> importSongs() async {
    _logger.i(_importStartLog);

    final String? userId = _auth.currentUser?.uid;
    if (userId == null) {
      _logger.w(_importNotAuthenticatedLog);
      _status.value = _statusUnauthorizedError;
      return const Result.failure(_userNotAuthenticated);
    }

    try {
      _status.value = _statusImporting;

      final String? fileContent = await _dataSource.pickBackupFile();
      if (fileContent == null) {
        _logger.i(_importCancelledLog);
        _status.value = _pickerCancelled;
        return Result.ok;
      }

      final BackupDataModel backupDataModel = BackupDataModel.fromJson(fileContent);

      for (final Map<String, dynamic> songJson in backupDataModel.songs) {
        final SongModel songModel = SongModel(
          id: _newDocumentId,
          author: songJson[_authorField] as String,
          name: songJson[_nameField] as String,
          album: songJson[_albumField] as String?,
          lyrics: songJson[_lyricsField] as String,
          coverIds: List<String>.from(songJson[_coverIdsField] as List<dynamic>),
        );

        await _songService.addSong(userId: userId, song: songModel);
      }

      _logger.i('$_importSuccessLog${backupDataModel.songs.length}$_importedSongsLog');
      _status.value = _statusSuccess;
      return Result.ok;
    } on Exception catch (e) {
      _logger.e('$_importFailureLog$e');
      _status.value = _importFailedMessage;
      return const Result.failure(_importFailedMessage);
    }
  }

  /// Encodes a song into a JSON-serializable map.
  Map<String, dynamic> _encodeSong(Song song) {
    return <String, dynamic>{
      _idField: song.id,
      _authorField: song.author,
      _nameField: song.name,
      _albumField: song.album,
      _lyricsField: song.lyrics,
      _coverIdsField: song.covers.map(_coverId).toList(),
    };
  }

  String _coverId(Cover cover) => cover.id;
}
