import 'dart:async';
import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:firebase_storage/firebase_storage.dart' as firebase_storage;
import 'package:flutter/foundation.dart' show ValueNotifier;

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
  })  : _songService = songService,
        _auth = auth,
        _storage = storage;

  @override
  Future<void> init() async {
    _currentUserId = _auth.currentUser?.uid;
    if (_currentUserId == null) {
      return;
    }

    _songService.watchSongs(_currentUserId!).listen(
      (List<SongModel> models) {
        _processModels(models);
      },
      onError: (Object e) {
        _songs.value = const [];
      },
    );
  }

  void _processModels(List<SongModel> models) {
    final List<Song> songs = [];

    for (final model in models) {
      final List<Cover> covers = [];

      if (model.coverIds.isNotEmpty) {
        _songService.watchCovers(_currentUserId!, model.id).listen(
          (List<CoverModel> coverModels) {
            for (final coverModel in coverModels) {
              covers.add(coverModel.toEntity());
            }
          },
          onError: (_) {},
        );
      }

      songs.add(model.toEntity(covers: covers));
    }

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
      final userId = _currentUserId;
      if (userId == null) {
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

      final Uint8List audioData = const <int>[];

      await _songService.addSong(
        userId: userId,
        song: song,
        audioData: audioData,
      );

      return Result.success();
    } catch (e) {
      return Result.failure(e as String);
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
      final userId = _currentUserId;
      if (userId == null) {
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
      return Result.success();
    } catch (e) {
      return Result.failure(e as String);
    }
  }

  @override
  Future<Result<void>> deleteSong({
    required String songId,
  }) async {
    try {
      final userId = _currentUserId;
      if (userId == null) {
        return Result.failure('Користувач не авторизований.');
      }

      await _songService.deleteSong(userId: userId, songId: songId);
      return Result.success();
    } catch (e) {
      return Result.failure(e as String);
    }
  }

  @override
  Future<Result<void>> addCover({
    required String songId,
    required List<int> audioBytes,
    String? notes,
  }) async {
    try {
      final userId = _currentUserId;
      if (userId == null) {
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

      return Result.success();
    } catch (e) {
      return Result.failure(e as String);
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
      final userId = _currentUserId;
      if (userId == null) {
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

      return Result.success();
    } catch (e) {
      return Result.failure(e as String);
    }
  }

  @override
  Future<Result<void>> deleteCover({
    required String songId,
    required String coverId,
  }) async {
    try {
      final userId = _currentUserId;
      if (userId == null) {
        return Result.failure('Користувач не авторизований.');
      }

      await _songService.deleteCover(
        userId: userId,
        songId: songId,
        coverId: coverId,
      );

      return Result.success();
    } catch (e) {
      return Result.failure(e as String);
    }
  }
}
