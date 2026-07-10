import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:flutter/foundation.dart' show ValueNotifier;
import 'package:hitwave.cover/core/domain/result.dart';
import 'package:hitwave.cover/features/backup/data/data_sources/backup_data_source.dart';
import 'package:hitwave.cover/features/backup/data/models/backup_data_model.dart';
import 'package:hitwave.cover/features/song/data/data_sources/firebase_song_service.dart';
import 'package:hitwave.cover/features/song/data/models/song_model.dart';
import 'package:hitwave.cover/features/song/domain/repositories/song_repository.dart';
import 'package:logger/logger.dart';

import '../../domain/repositories/backup_repository.dart';

/// Firebase-based implementation of [BackupRepository].
///
/// Handles exporting songs to JSON files and importing songs from JSON files,
/// persisting them to Firebase. File picker operations are encapsulated
/// internally — the interface exposes no file paths.
final class BackupRepositoryImpl implements BackupRepository {
  static const String _statusIdle = 'idle';
  static const String _statusExporting = 'exporting';
  static const String _statusImporting = 'importing';
  static const String _statusSuccess = 'success';
  static const String _statusUnauthorizedError = 'Помилка: користувач не авторизований';
  static const String _userNotAuthenticated = 'Користувач не авторизований.';
  static const String _pickerCancelled = 'Вибір скасовано';
  static const String _idField = 'id';
  static const String _authorField = 'author';
  static const String _nameField = 'name';
  static const String _albumField = 'album';
  static const String _lyricsField = 'lyrics';
  static const String _coverIdsField = 'coverIds';

  final FirebaseSongService _songService;
  final SongRepository _songRepository;
  final BackupDataSource _dataSource;
  final firebase_auth.FirebaseAuth _auth;
  final Logger _logger;

  final ValueNotifier<String> _status = ValueNotifier(_statusIdle);

  @override
  ValueNotifier<String> get status => _status;

  /// Creates a new [BackupRepositoryImpl].
  BackupRepositoryImpl({
    required FirebaseSongService songService,
    required SongRepository songRepository,
    required BackupDataSource dataSource,
    required firebase_auth.FirebaseAuth auth,
    required Logger logger,
  })  : _songService = songService,
        _songRepository = songRepository,
        _dataSource = dataSource,
        _auth = auth,
        _logger = logger;

  @override
  Future<Result<void>> exportSongs() async {
    try {
      _logger.i('ExportSongs: starting');

      final userId = _auth.currentUser?.uid;
      if (userId == null) {
        _logger.w('ExportSongs: failed — користувач не авторизований');
        _status.value = _statusUnauthorizedError;
        return Result.failure(_userNotAuthenticated);
      }

      _status.value = _statusExporting;

      final String? filePath = await _dataSource.pickExportDirectory();
      if (filePath == null) {
        _logger.i('ExportSongs: cancelled by user');
        _status.value = _pickerCancelled;
        return Result.success();
      }

      final songs = _songRepository.songs.value;

      final model = BackupDataModel(
        exportedAt: DateTime.now(),
        songs: songs.map(_encodeSong).toList(),
      );

      final file = File(filePath);
      await file.writeAsString(model.toJson());

      _logger.i('ExportSongs: success — exported ${songs.length} songs to "$filePath"');
      _status.value = _statusSuccess;
      return Result.success();
    } catch (e) {
      _logger.e('ExportSongs: failure — $e');
      _status.value = 'Помилка: $e';
      return Result.failure('Помилка при експорті: $e');
    }
  }

  @override
  Future<Result<void>> importSongs() async {
    try {
      _logger.i('ImportSongs: starting');

      final userId = _auth.currentUser?.uid;
      if (userId == null) {
        _logger.w('ImportSongs: failed — користувач не авторизований');
        _status.value = _statusUnauthorizedError;
        return Result.failure(_userNotAuthenticated);
      }

      _status.value = _statusImporting;

      final String? fileContent = await _dataSource.pickBackupFile();
      if (fileContent == null) {
        _logger.i('ImportSongs: cancelled by user');
        _status.value = _pickerCancelled;
        return Result.success();
      }

      final backupDataModel = BackupDataModel.fromJson(fileContent);

      for (final songJson in backupDataModel.songs) {
        final songModel = SongModel(
          id: '',
          author: songJson[_authorField] as String,
          name: songJson[_nameField] as String,
          album: songJson[_albumField] as String?,
          lyrics: songJson[_lyricsField] as String,
          coverIds: List<String>.from(songJson[_coverIdsField] as List<dynamic>),
        );

        await _songService.addSong(userId: userId, song: songModel);
      }

      _logger.i('ImportSongs: success — ${backupDataModel.songs.length} songs imported');
      _status.value = _statusSuccess;
      return Result.success();
    } catch (e) {
      _logger.e('ImportSongs: failure — $e');
      _status.value = 'Помилка: $e';
      return Result.failure('Помилка при імпорті: $e');
    }
  }

  /// Encodes a song from the songs list into a JSON-serializable map.
  Map<String, dynamic> _encodeSong(dynamic song) {
    final dynamic covers = song.covers;
    return {
      _idField: song.id,
      _authorField: song.author,
      _nameField: song.name,
      _albumField: song.album,
      _lyricsField: song.lyrics,
      _coverIdsField: List<dynamic>.from(covers.map((dynamic cover) => cover.id)),
    };
  }
}
