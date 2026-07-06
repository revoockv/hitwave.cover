import 'dart:async';
import 'dart:typed_data';

import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:firebase_storage/firebase_storage.dart' as firebase_storage;
import 'package:flutter/foundation.dart' show ValueNotifier;
import 'package:logger/logger.dart';

import '../../../../core/domain/result.dart';
import '../../domain/entities/cover.dart';
import '../../domain/entities/song.dart';
import '../../domain/repositories/song_repository.dart';
import '../datasources/firebase_song_service.dart';
import '../models/cover_model.dart';
import '../models/song_model.dart';

/// Firebase-based implementation of [SongRepository].
///
/// Subscribes to Firebase Firestore song changes and exposes the current
/// song list as a [ValueNotifier<List<Song>]> for reactive UI updates.
final class SongRepositoryImpl implements SongRepository {
  final FirebaseSongService _songService;
  final firebase_auth.FirebaseAuth _auth;
  final firebase_storage.FirebaseStorage _storage;
  final Logger _logger;

  /// Exposes the current song list as a [ValueNotifier].
  ///
  /// Contains a [List<Song>] sorted by name.
  final ValueNotifier<List<Song>> _songs = ValueNotifier(const []);

  @override
  ValueNotifier<List<Song>> get songs => _songs;

  String? _currentUserId;

  /// Creates a new [SongRepositoryImpl].
  SongRepositoryImpl({
    required FirebaseSongService songService,
    required firebase_auth.FirebaseAuth auth,
    required firebase_storage.FirebaseStorage storage,
    required Logger logger,
  })  : _songService = songService,
        _auth = auth,
        _storage = storage,
        _logger = logger;

  @override
  Future<void> init() async {
    _currentUserId = _auth.currentUser?.uid;
    if (_currentUserId == null) {
      _logger.i('Song repository init: no authenticated user, skipping subscription');
      return;
    }

    _logger.i('Song repository init: subscribed to songs for user $_currentUserId');

    _songService.watchSongs(_currentUserId!).listen(
      (List<SongModel> models) {
        _processModels(models);
      },
      onError: (Object e) {
        _logger.e('Song repository watchSongs stream error: $e');
        _songs.value = const [];
      },
    );
  }

  void _processModels(List<SongModel> models) async {
    final String userId = _currentUserId!;

    final List<Song> songs = await Future.wait(
      models.map(
        (SongModel model) async {
          final List<Cover> covers = model.coverIds.isEmpty
              ? const []
              : await _songService.getCovers(userId, model.id).then(
                  (List<CoverModel> coverModels) {
                    return coverModels.map((CoverModel coverModel) {
                      return coverModel.toEntity();
                    }).toList();
                  },
                );

          return model.toEntity(covers: covers);
        },
      ),
    );

    _songs.value = songs;
  }

  @override
  Future<Result<void>> addSong({
    required String author,
    required String name,
    String? album,
    required String lyrics,
  }) async {
    try {
      _logger.i('AddSong: starting for author="$author", name="$name"');

      final userId = _currentUserId;
      if (userId == null) {
        _logger.w('AddSong: failed — користувач не авторизований');
        return Result.failure('Користувач не авторизований.');
      }

      final song = SongModel(
        id: '',
        author: author,
        name: name,
        album: album,
        lyrics: lyrics,
        coverIds: const [],
      );

      await _songService.addSong(
        userId: userId,
        song: song,
        audioData: Uint8List.fromList(const <int>[]),
      );

      _logger.i('AddSong: success — song "$name" by "$author" added');
      return Result.success();
    } catch (e) {
      _logger.e('AddSong: failure — $e');
      return Result.failure('Помилка при додаванні пісні: $e');
    }
  }

  @override
  Future<Result<void>> updateSong({
    required String songId,
    required String author,
    required String name,
    String? album,
    required String lyrics,
  }) async {
    try {
      _logger.i('UpdateSong: starting for songId="$songId", name="$name"');

      final userId = _currentUserId;
      if (userId == null) {
        _logger.w('UpdateSong: failed — користувач не авторизований');
        return Result.failure('Користувач не авторизований.');
      }

      final song = SongModel(
        id: songId,
        author: author,
        name: name,
        album: album,
        lyrics: lyrics,
        coverIds: const [],
      );

      await _songService.updateSong(userId: userId, song: song);
      _logger.i('UpdateSong: success — song "$name" updated');
      return Result.success();
    } catch (e) {
      _logger.e('UpdateSong: failure — $e');
      return Result.failure('Помилка при оновленні пісні: $e');
    }
  }

  @override
  Future<Result<void>> deleteSong({
    required String songId,
  }) async {
    try {
      _logger.i('DeleteSong: starting for songId="$songId"');

      final userId = _currentUserId;
      if (userId == null) {
        _logger.w('DeleteSong: failed — користувач не авторизований');
        return Result.failure('Користувач не авторизований.');
      }

      await _songService.deleteSong(userId: userId, songId: songId);
      _logger.i('DeleteSong: success — song "$songId" deleted');
      return Result.success();
    } catch (e) {
      _logger.e('DeleteSong: failure — $e');
      return Result.failure('Помилка при видаленні пісні: $e');
    }
  }

  @override
  Future<Result<void>> addCover({
    required String songId,
    required List<int> audioBytes,
    String? notes,
  }) async {
    try {
      _logger.i('AddCover: starting for songId="$songId", size=${audioBytes.length} bytes');

      final userId = _currentUserId;
      if (userId == null) {
        _logger.w('AddCover: failed — користувач не авторизований');
        return Result.failure('Користувач не авторизований.');
      }

      final cover = CoverModel(
        id: '',
        timestamp: DateTime.now().millisecondsSinceEpoch,
        audioBytes: audioBytes,
        notes: notes,
      );

      final Uint8List audioData = Uint8List.fromList(audioBytes);

      await _songService.addCover(
        userId: userId,
        songId: songId,
        cover: cover,
        audioData: audioData,
      );

      _logger.i('AddCover: success — cover added to song "$songId"');
      return Result.success();
    } catch (e) {
      _logger.e('AddCover: failure — $e');
      return Result.failure('Помилка: $e');
    }
  }

  @override
  Future<Result<void>> updateCover({
    required String songId,
    required String coverId,
    required List<int> audioBytes,
    String? notes,
  }) async {
    try {
      _logger.i('UpdateCover: starting for songId="$songId", coverId="$coverId", size=${audioBytes.length} bytes');

      final userId = _currentUserId;
      if (userId == null) {
        _logger.w('UpdateCover: failed — користувач не авторизований');
        return Result.failure('Користувач не авторизований.');
      }

      final cover = CoverModel(
        id: coverId,
        timestamp: DateTime.now().millisecondsSinceEpoch,
        audioBytes: audioBytes,
        notes: notes,
      );

      final Uint8List audioData = Uint8List.fromList(audioBytes);

      await _songService.updateCover(
        userId: userId,
        songId: songId,
        cover: cover,
        audioData: audioData,
      );

      _logger.i('UpdateCover: success — cover "$coverId" updated on song "$songId"');
      return Result.success();
    } catch (e) {
      _logger.e('UpdateCover: failure — $e');
      return Result.failure('Помилка: $e');
    }
  }

  @override
  Future<Result<void>> deleteCover({
    required String songId,
    required String coverId,
  }) async {
    try {
      _logger.i('DeleteCover: starting for songId="$songId", coverId="$coverId"');

      final userId = _currentUserId;
      if (userId == null) {
        _logger.w('DeleteCover: failed — користувач не авторизований');
        return Result.failure('Користувач не авторизований.');
      }

      await _songService.deleteCover(
        userId: userId,
        songId: songId,
        coverId: coverId,
      );

      _logger.i('DeleteCover: success — cover "$coverId" deleted from song "$songId"');
      return Result.success();
    } catch (e) {
      _logger.e('DeleteCover: failure — $e');
      return Result.failure('Помилка: $e');
    }
  }
}
