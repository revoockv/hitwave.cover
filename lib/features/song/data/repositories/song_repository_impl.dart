import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:flutter/foundation.dart';
import 'package:logger/logger.dart';

import '../../../../core/domain/entities/disposable_resource.dart';
import '../../../../core/domain/entities/result.dart';
import '../../domain/entities/cover.dart';
import '../../domain/entities/song.dart';
import '../../domain/repositories/song_repository.dart';
import '../data_sources/firebase_song_service.dart';
import '../models/cover_model.dart';
import '../models/song_model.dart';

/// Firebase-based implementation of [SongRepository].
///
/// Subscribes to Firebase Firestore song changes in [init] and keeps the
/// current song list in a private [ValueNotifier], exposed as [ValueListenable].
final class SongRepositoryImpl implements SongRepository, DisposableResource {
  static const String _userNotAuthenticated = 'Користувач не авторизований.';
  static const String _addSongFailedMessage = 'Помилка при додаванні пісні.';
  static const String _updateSongFailedMessage = 'Помилка при оновленні пісні.';
  static const String _deleteSongFailedMessage = 'Помилка при видаленні пісні.';
  static const String _addCoverFailedMessage = 'Помилка при додаванні обкладинки.';
  static const String _updateCoverFailedMessage = 'Помилка при оновленні обкладинки.';
  static const String _deleteCoverFailedMessage = 'Помилка при видаленні обкладинки.';

  static const String _newDocumentId = '';

  static const String _initNoUserLog = 'Song repository init: no authenticated user, skipping subscription';
  static const String _initSubscribedLog = 'Song repository init: subscribed to songs for user ';
  static const String _streamErrorLog = 'Song repository watchSongs stream error: ';
  static const String _disposeLog = 'Song repository dispose: unsubscribed';

  static const String _addSongLog = 'AddSong';
  static const String _updateSongLog = 'UpdateSong';
  static const String _deleteSongLog = 'DeleteSong';
  static const String _addCoverLog = 'AddCover';
  static const String _updateCoverLog = 'UpdateCover';
  static const String _deleteCoverLog = 'DeleteCover';

  static const String _startingLog = ': starting for songId="';
  static const String _startingNameLog = ': starting for name="';
  static const String _successLog = ': success — songId="';
  static const String _successNameLog = ': success — name="';
  static const String _coverIdLog = '", coverId="';
  static const String _closingQuoteLog = '"';
  static const String _notAuthenticatedLog = ': failed — user is not authenticated';
  static const String _failureLog = ': failure — ';

  final FirebaseSongService _songService;
  final firebase_auth.FirebaseAuth _auth;
  final Logger _logger;

  final ValueNotifier<List<Song>> _songs = ValueNotifier<List<Song>>(const <Song>[]);

  StreamSubscription<List<SongModel>>? _subscription;

  String? _currentUserId;

  /// Creates a new [SongRepositoryImpl].
  SongRepositoryImpl({
    required this._songService,
    required this._auth,
    required this._logger,
  });

  /// Subscribes to the songs of the signed-in user; returns this for `registerSingletonAsync`.
  Future<SongRepositoryImpl> init() async {
    final String? userId = _auth.currentUser?.uid;
    _currentUserId = userId;
    if (userId == null) {
      _logger.i(_initNoUserLog);
      return this;
    }

    _subscription ??= _songService.watchSongs(userId).listen(_onSongModels, onError: _onSongsError);
    _logger.i('$_initSubscribedLog$userId');
    return this;
  }

  /// Cancels the subscription and releases the state.
  @override
  Future<void> dispose() async {
    await _subscription?.cancel();
    _subscription = null;
    _songs.dispose();
    _logger.i(_disposeLog);
  }

  @override
  ValueListenable<List<Song>> watchSongs() => _songs;

  void _onSongModels(List<SongModel> models) {
    unawaited(_processModels(models));
  }

  void _onSongsError(Object error) {
    _logger.e('$_streamErrorLog$error');
    _songs.value = const <Song>[];
  }

  Future<void> _processModels(List<SongModel> models) async {
    final String? userId = _currentUserId;
    if (userId == null) {
      return;
    }

    final List<Song> songs = await Future.wait(
      models.map((SongModel model) => _toSong(userId, model)),
    );

    _songs.value = songs;
  }

  Future<Song> _toSong(String userId, SongModel model) async {
    if (model.coverIds.isEmpty) {
      return model.toEntity(covers: const <Cover>[]);
    }

    final List<CoverModel> coverModels = await _songService.getCovers(userId, model.id);
    return model.toEntity(covers: coverModels.map(_toCover).toList());
  }

  Cover _toCover(CoverModel model) => model.toEntity();

  @override
  Future<Result<void>> addSong({
    required String author,
    required String name,
    String? album,
    required String lyrics,
  }) async {
    _logger.i('$_addSongLog$_startingNameLog$name$_closingQuoteLog');

    final String? userId = _currentUserId;
    if (userId == null) {
      _logger.w('$_addSongLog$_notAuthenticatedLog');
      return const Result.failure(_userNotAuthenticated);
    }

    try {
      final SongModel song = SongModel(
        id: _newDocumentId,
        author: author,
        name: name,
        album: album,
        lyrics: lyrics,
        coverIds: const <String>[],
      );

      await _songService.addSong(userId: userId, song: song);

      _logger.i('$_addSongLog$_successNameLog$name$_closingQuoteLog');
      return Result.ok;
    } on Exception catch (e) {
      _logger.e('$_addSongLog$_failureLog$e');
      return const Result.failure(_addSongFailedMessage);
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
    _logger.i('$_updateSongLog$_startingLog$songId$_closingQuoteLog');

    final String? userId = _currentUserId;
    if (userId == null) {
      _logger.w('$_updateSongLog$_notAuthenticatedLog');
      return const Result.failure(_userNotAuthenticated);
    }

    try {
      final SongModel song = SongModel(
        id: songId,
        author: author,
        name: name,
        album: album,
        lyrics: lyrics,
        coverIds: const <String>[],
      );

      await _songService.updateSong(userId: userId, song: song);

      _logger.i('$_updateSongLog$_successLog$songId$_closingQuoteLog');
      return Result.ok;
    } on Exception catch (e) {
      _logger.e('$_updateSongLog$_failureLog$e');
      return const Result.failure(_updateSongFailedMessage);
    }
  }

  @override
  Future<Result<void>> deleteSong({
    required String songId,
  }) async {
    _logger.i('$_deleteSongLog$_startingLog$songId$_closingQuoteLog');

    final String? userId = _currentUserId;
    if (userId == null) {
      _logger.w('$_deleteSongLog$_notAuthenticatedLog');
      return const Result.failure(_userNotAuthenticated);
    }

    try {
      await _songService.deleteSong(userId: userId, songId: songId);

      _logger.i('$_deleteSongLog$_successLog$songId$_closingQuoteLog');
      return Result.ok;
    } on Exception catch (e) {
      _logger.e('$_deleteSongLog$_failureLog$e');
      return const Result.failure(_deleteSongFailedMessage);
    }
  }

  @override
  Future<Result<void>> addCover({
    required String songId,
    required List<int> audioBytes,
    String? notes,
  }) async {
    _logger.i('$_addCoverLog$_startingLog$songId$_closingQuoteLog');

    final String? userId = _currentUserId;
    if (userId == null) {
      _logger.w('$_addCoverLog$_notAuthenticatedLog');
      return const Result.failure(_userNotAuthenticated);
    }

    try {
      final CoverModel cover = CoverModel(
        id: _newDocumentId,
        timestamp: DateTime.now().millisecondsSinceEpoch,
        audioBytes: audioBytes,
        notes: notes,
      );

      await _songService.addCover(userId: userId, songId: songId, cover: cover);

      _logger.i('$_addCoverLog$_successLog$songId$_closingQuoteLog');
      return Result.ok;
    } on Exception catch (e) {
      _logger.e('$_addCoverLog$_failureLog$e');
      return const Result.failure(_addCoverFailedMessage);
    }
  }

  @override
  Future<Result<void>> updateCover({
    required String songId,
    required String coverId,
    required List<int> audioBytes,
    String? notes,
  }) async {
    _logger.i('$_updateCoverLog$_startingLog$songId$_coverIdLog$coverId$_closingQuoteLog');

    final String? userId = _currentUserId;
    if (userId == null) {
      _logger.w('$_updateCoverLog$_notAuthenticatedLog');
      return const Result.failure(_userNotAuthenticated);
    }

    try {
      final CoverModel cover = CoverModel(
        id: coverId,
        timestamp: DateTime.now().millisecondsSinceEpoch,
        audioBytes: audioBytes,
        notes: notes,
      );

      await _songService.updateCover(userId: userId, songId: songId, cover: cover);

      _logger.i('$_updateCoverLog$_successLog$songId$_coverIdLog$coverId$_closingQuoteLog');
      return Result.ok;
    } on Exception catch (e) {
      _logger.e('$_updateCoverLog$_failureLog$e');
      return const Result.failure(_updateCoverFailedMessage);
    }
  }

  @override
  Future<Result<void>> deleteCover({
    required String songId,
    required String coverId,
  }) async {
    _logger.i('$_deleteCoverLog$_startingLog$songId$_coverIdLog$coverId$_closingQuoteLog');

    final String? userId = _currentUserId;
    if (userId == null) {
      _logger.w('$_deleteCoverLog$_notAuthenticatedLog');
      return const Result.failure(_userNotAuthenticated);
    }

    try {
      await _songService.deleteCover(userId: userId, songId: songId, coverId: coverId);

      _logger.i('$_deleteCoverLog$_successLog$songId$_coverIdLog$coverId$_closingQuoteLog');
      return Result.ok;
    } on Exception catch (e) {
      _logger.e('$_deleteCoverLog$_failureLog$e');
      return const Result.failure(_deleteCoverFailedMessage);
    }
  }
}
