import 'dart:io';

import 'package:flutter/foundation.dart' show ValueNotifier;
import 'package:hitwave.cover/core/domain/result.dart';
import 'package:hitwave.cover/features/backup/data/models/backup_data_model.dart';
import 'package:hitwave.cover/features/song/data/datasources/firebase_song_service.dart';
import 'package:hitwave.cover/features/song/data/models/song_model.dart';
import 'package:hitwave.cover/features/song/domain/entities/song.dart';
import 'package:hitwave.cover/features/song/domain/repositories/song_repository.dart';
import 'package:logger/logger.dart';

import '../../domain/repositories/backup_repository.dart';

/// Firebase-based implementation of [BackupRepository].
///
/// Handles exporting songs to JSON files and importing songs from JSON files,
/// persisting them to Firebase using [FirebaseSongService].
final class BackupRepositoryImpl implements BackupRepository {
  final FirebaseSongService _songService;
  final SongRepository _songRepository;
  final Logger _logger;

  final ValueNotifier<String> _status = ValueNotifier('idle');

  @override
  ValueNotifier<String> get status => _status;

  String? _currentUserId;

  /// Creates a new [BackupRepositoryImpl].
  BackupRepositoryImpl({
    required FirebaseSongService songService,
    required SongRepository songRepository,
    required Logger logger,
  })  : _songService = songService,
        _songRepository = songRepository,
        _logger = logger;

  @override
  Future<Result<void>> exportSongs(String filePath) async {
    try {
      _logger.i('ExportSongs: starting for user $_currentUserId');

      final userId = _currentUserId;
      if (userId == null) {
        _logger.w('ExportSongs: failed — користувач не авторизований');
        _status.value = 'Помилка: користувач не авторизований';
        return Result.failure('Користувач не авторизований.');
      }

      _status.value = 'exporting';

      final songs = _songRepository.songs.value;

      final model = BackupDataModel(
        exportedAt: DateTime.now(),
        songs: songs.map(_encodeSong).toList(),
      );

      final file = File(filePath);
      await file.writeAsString(model.toJson());

      _logger.i(
        'ExportSongs: success — exported ${songs.length} songs to "$filePath"',
      );
      _status.value = 'success';
      return Result.success();
    } catch (e) {
      _logger.e('ExportSongs: failure — $e');
      _status.value = 'Помилка: $e';
      return Result.failure('Помилка при експорті: $e');
    }
  }

  @override
  Future<Result<void>> importSongs(String filePath) async {
    try {
      _logger.i('ImportSongs: starting from "$filePath"');

      final userId = _currentUserId;
      if (userId == null) {
        _logger.w('ImportSongs: failed — користувач не авторизований');
        _status.value = 'Помилка: користувач не авторизований';
        return Result.failure('Користувач не авторизований.');
      }

      _status.value = 'importing';

      final file = File(filePath);
      final jsonString = await file.readAsString();

      final backupDataModel = BackupDataModel.fromJson(jsonString);

      for (final songJson in backupDataModel.songs) {
        final songModel = SongModel(
          id: '',
          author: songJson['author'] as String,
          name: songJson['name'] as String,
          album: songJson['album'] as String?,
          lyrics: songJson['lyrics'] as String,
          coverIds: List<String>.from(songJson['coverIds'] as List<dynamic>),
        );

        await _songService.addSong(userId: userId, song: songModel);
      }

      _logger.i('ImportSongs: success — ${backupDataModel.songs.length} songs imported');
      _status.value = 'success';
      return Result.success();
    } catch (e) {
      _logger.e('ImportSongs: failure — $e');
      _status.value = 'Помилка: $e';
      return Result.failure('Помилка при імпорті: $e');
    }
  }

  /// Encodes a [Song] entity into a JSON-serializable map.
  Map<String, dynamic> _encodeSong(Song song) {
    return {
      'id': song.id,
      'author': song.author,
      'name': song.name,
      'album': song.album,
      'lyrics': song.lyrics,
      'coverIds': song.covers.map((cover) => cover.id).toList(),
    };
  }
}
