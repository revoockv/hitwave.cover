import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:logger/logger.dart';

import '../../../../core/domain/entities/disposable_resource.dart';
import '../../../../core/domain/entities/result.dart';
import '../../../auth/domain/entities/auth_session.dart';
import '../../domain/entities/cover.dart';
import '../../domain/entities/song.dart';
import '../../domain/repositories/song_repository.dart';
import '../data_sources/hive_song_service.dart';
import '../data_sources/song_data_source.dart';
import '../models/cover_model.dart';
import '../models/song_model.dart';

/// Implementation of [SongRepository] that follows the session.
///
/// A signed-in user keeps the songs in Firestore, a guest keeps them on the
/// device in Hive, and nobody is signed out with no songs. On every session
/// change [init]'s listener switches the [SongDataSource], subscribes to its
/// songs and keeps them in a private [ValueNotifier], exposed as [ValueListenable].
/// After a sign-in it offers the songs left on the device for the account.
final class SongRepositoryImpl implements SongRepository, DisposableResource {
  static const String _userNotAuthenticated = 'Спершу увійдіть або продовжте без акаунта.';
  static const String _addSongFailedMessage = 'Помилка при додаванні пісні.';
  static const String _updateSongFailedMessage = 'Помилка при оновленні пісні.';
  static const String _deleteSongFailedMessage = 'Помилка при видаленні пісні.';
  static const String _updateSpeedFailedMessage = 'Не вдалося зберегти швидкість.';
  static const String _updateLeadInFailedMessage = 'Не вдалося зберегти відступ.';
  static const String _updateLyricsFailedMessage = 'Не вдалося зберегти текст.';
  static const String _addSongsFailedMessage = 'Не вдалося додати пісні.';
  static const String _transferFailedMessage = 'Не вдалося перенести всі пісні в акаунт. Решта лишилась на пристрої.';
  static const String _keepFailedMessage = 'Не вдалося запамʼятати вибір.';
  static const String _addCoverFailedMessage = 'Помилка при додаванні обкладинки.';
  static const String _updateCoverFailedMessage = 'Помилка при оновленні обкладинки.';
  static const String _deleteCoverFailedMessage = 'Помилка при видаленні обкладинки.';

  static const String _newDocumentId = '';

  static const String _signedOutLog = 'Song repository: signed out, no songs';
  static const String _guestLog = 'Song repository: guest, songs on the device';
  static const String _signedInLog = 'Song repository: songs of user ';
  static const String _streamErrorLog = 'Song repository watchSongs stream error: ';
  static const String _disposeLog = 'Song repository dispose: unsubscribed';

  static const String _addSongLog = 'AddSong';
  static const String _updateSongLog = 'UpdateSong';
  static const String _deleteSongLog = 'DeleteSong';
  static const String _updateSpeedLog = 'UpdateSongScrollSpeed';
  static const String _speedLog = '", speed=';
  static const String _updateLeadInLog = 'UpdateSongLeadIn';
  static const String _leadInLog = '", leadIn=';
  static const String _updateLyricsLog = 'UpdateSongLyrics';
  static const String _addSongsLog = 'AddSongs';
  static const String _transferLog = 'TransferLocalSongs';
  static const String _keepLog = 'KeepLocalSongs';
  static const String _addCoverLog = 'AddCover';
  static const String _updateCoverLog = 'UpdateCover';
  static const String _deleteCoverLog = 'DeleteCover';

  static const String _startingLog = ': starting for songId="';
  static const String _startingNameLog = ': starting for name="';
  static const String _startingCountLog = ': starting for songs: ';
  static const String _successLog = ': success';
  static const String _successCountLog = ': success — songs: ';
  static const String _coverIdLog = '", coverId="';
  static const String _closingQuoteLog = '"';
  static const String _notAuthenticatedLog = ': failed — nobody is signed in';
  static const String _failureLog = ': failure — ';

  /// Makes the data source of the account [userId] (Firestore in the app).
  final SongDataSource Function(String userId) _accountSongsOf;
  final HiveSongService _localSongService;
  final ValueListenable<AuthSession> _session;
  final Logger _logger;

  final ValueNotifier<List<Song>> _songs = ValueNotifier<List<Song>>(const <Song>[]);

  final ValueNotifier<int> _localSongsToTransfer = ValueNotifier<int>(0);

  SongDataSource? _dataSource;

  StreamSubscription<List<SongModel>>? _subscription;

  /// Creates a new [SongRepositoryImpl] that follows [session].
  SongRepositoryImpl({
    required this._accountSongsOf,
    required this._localSongService,
    required this._session,
    required this._logger,
  });

  /// Starts following the session; returns this for `registerSingletonAsync`.
  Future<SongRepositoryImpl> init() async {
    _session.addListener(_onSessionChanged);
    await _useSession(_session.value);
    return this;
  }

  /// Stops following the session, cancels the subscription and releases the state.
  @override
  Future<void> dispose() async {
    _session.removeListener(_onSessionChanged);
    await _subscription?.cancel();
    _subscription = null;
    _songs.dispose();
    _localSongsToTransfer.dispose();
    _logger.i(_disposeLog);
  }

  @override
  ValueListenable<List<Song>> watchSongs() => _songs;

  @override
  ValueListenable<int> watchLocalSongsToTransfer() => _localSongsToTransfer;

  void _onSessionChanged() {
    unawaited(_useSession(_session.value));
  }

  Future<void> _useSession(AuthSession session) async {
    await _subscription?.cancel();
    _subscription = null;
    _songs.value = const <Song>[];

    final SongDataSource? dataSource = switch (session) {
      SignedOutAuthSession() => null,
      GuestAuthSession() => _localSongService,
      SignedInAuthSession(:final user) => _accountSongsOf(user.id),
    };
    _dataSource = dataSource;
    _updateLocalSongsToTransfer();

    switch (session) {
      case SignedOutAuthSession():
        _logger.i(_signedOutLog);
      case GuestAuthSession():
        _logger.i(_guestLog);
      case SignedInAuthSession(:final user):
        _logger.i('$_signedInLog${user.id}');
    }
    if (dataSource == null) return;

    _subscription = dataSource.watchSongs().listen(
      (List<SongModel> models) => _onSongModels(dataSource, models),
      onError: _onSongsError,
    );
  }

  /// Offers the songs on the device after a sign-in, unless the user already refused them.
  void _updateLocalSongsToTransfer() {
    final bool offer = _session.value is SignedInAuthSession && !_localSongService.isTransferDeclined;
    _localSongsToTransfer.value = offer ? _localSongService.songCount : 0;
  }

  void _onSongModels(SongDataSource dataSource, List<SongModel> models) {
    unawaited(_processModels(dataSource, models));
  }

  void _onSongsError(Object error) {
    _logger.e('$_streamErrorLog$error');
    _songs.value = const <Song>[];
  }

  Future<void> _processModels(SongDataSource dataSource, List<SongModel> models) async {
    final List<Song> songs = await Future.wait(models.map((SongModel model) => _toSong(dataSource, model)));
    if (!identical(dataSource, _dataSource)) return;

    _songs.value = songs;
  }

  Future<Song> _toSong(SongDataSource dataSource, SongModel model) async {
    if (model.coverIds.isEmpty) {
      return model.toEntity(covers: const <Cover>[]);
    }

    final List<CoverModel> coverModels = await dataSource.getCovers(model.id);
    return model.toEntity(covers: coverModels.map(_toCover).toList());
  }

  Cover _toCover(CoverModel model) => model.toEntity();

  /// Runs [operation] on the data source of the session and logs it as [logName].
  Future<Result<void>> _run(
    String logName,
    String startDetails,
    String failureMessage,
    Future<void> Function(SongDataSource dataSource) operation,
  ) async {
    _logger.i('$logName$startDetails');

    final SongDataSource? dataSource = _dataSource;
    if (dataSource == null) {
      _logger.w('$logName$_notAuthenticatedLog');
      return const Result.failure(_userNotAuthenticated);
    }

    try {
      await operation(dataSource);
      _logger.i('$logName$_successLog');
      return Result.ok;
    } on Exception catch (e) {
      _logger.e('$logName$_failureLog$e');
      return Result.failure(failureMessage);
    }
  }

  @override
  Future<Result<void>> addSong({required String author, required String name, String? album, required String lyrics}) {
    final SongModel song = SongModel(
      id: _newDocumentId,
      author: author,
      name: name,
      album: album,
      lyrics: lyrics,
      coverIds: const <String>[],
    );
    return _run(
      _addSongLog,
      '$_startingNameLog$name$_closingQuoteLog',
      _addSongFailedMessage,
      (SongDataSource dataSource) => dataSource.addSong(song),
    );
  }

  @override
  Future<Result<void>> addSongs(List<Song> songs) {
    return _run(_addSongsLog, '$_startingCountLog${songs.length}', _addSongsFailedMessage, (
      SongDataSource dataSource,
    ) async {
      for (final Song song in songs) {
        await dataSource.addSong(SongModel.fromEntity(song));
      }
    });
  }

  @override
  Future<Result<void>> updateSong({
    required String songId,
    required String author,
    required String name,
    String? album,
    required String lyrics,
  }) {
    final SongModel song = SongModel(
      id: songId,
      author: author,
      name: name,
      album: album,
      lyrics: lyrics,
      coverIds: const <String>[],
    );
    return _run(
      _updateSongLog,
      '$_startingLog$songId$_closingQuoteLog',
      _updateSongFailedMessage,
      (SongDataSource dataSource) => dataSource.updateSong(song),
    );
  }

  @override
  Future<Result<void>> updateSongScrollSpeed({required String songId, required double speed}) {
    return _run(
      _updateSpeedLog,
      '$_startingLog$songId$_speedLog$speed',
      _updateSpeedFailedMessage,
      (SongDataSource dataSource) => dataSource.updateSongScrollSpeed(songId: songId, speed: speed),
    );
  }

  @override
  Future<Result<void>> updateSongLeadIn({required String songId, required double leadIn}) {
    return _run(
      _updateLeadInLog,
      '$_startingLog$songId$_leadInLog$leadIn',
      _updateLeadInFailedMessage,
      (SongDataSource dataSource) => dataSource.updateSongLeadIn(songId: songId, leadIn: leadIn),
    );
  }

  @override
  Future<Result<void>> updateSongLyrics({required String songId, required String lyrics}) {
    return _run(
      _updateLyricsLog,
      '$_startingLog$songId$_closingQuoteLog',
      _updateLyricsFailedMessage,
      (SongDataSource dataSource) => dataSource.updateSongLyrics(songId: songId, lyrics: lyrics),
    );
  }

  @override
  Future<Result<void>> deleteSong({required String songId}) {
    return _run(
      _deleteSongLog,
      '$_startingLog$songId$_closingQuoteLog',
      _deleteSongFailedMessage,
      (SongDataSource dataSource) => dataSource.deleteSong(songId),
    );
  }

  @override
  Future<Result<void>> transferLocalSongs() async {
    final List<SongModel> localSongs = _localSongService.readSongs();
    _logger.i('$_transferLog$_startingCountLog${localSongs.length}');

    final SongDataSource? account = _dataSource;
    if (_session.value is! SignedInAuthSession || account == null) {
      _logger.w('$_transferLog$_notAuthenticatedLog');
      return const Result.failure(_userNotAuthenticated);
    }

    try {
      for (final SongModel song in localSongs) {
        final List<CoverModel> covers = await _localSongService.getCovers(song.id);
        final String accountSongId = await account.addSong(song);
        for (final CoverModel cover in covers) {
          await account.addCover(songId: accountSongId, cover: cover);
        }
        // Deleted one by one, so a failure in the middle never copies a song twice.
        await _localSongService.deleteSong(song.id);
      }
      _localSongsToTransfer.value = 0;
      _logger.i('$_transferLog$_successCountLog${localSongs.length}');
      return Result.ok;
    } on Exception catch (e) {
      _logger.e('$_transferLog$_failureLog$e');
      _updateLocalSongsToTransfer();
      return const Result.failure(_transferFailedMessage);
    }
  }

  @override
  Future<Result<void>> keepLocalSongs() async {
    _logger.i(_keepLog);
    try {
      await _localSongService.setTransferDeclined(true);
      _localSongsToTransfer.value = 0;
      return Result.ok;
    } on Exception catch (e) {
      _logger.e('$_keepLog$_failureLog$e');
      return const Result.failure(_keepFailedMessage);
    }
  }

  @override
  Future<Result<void>> addCover({required String songId, required List<int> audioBytes, String? notes}) {
    final CoverModel cover = CoverModel(
      id: _newDocumentId,
      timestamp: DateTime.now().millisecondsSinceEpoch,
      audioBytes: audioBytes,
      notes: notes,
    );
    return _run(
      _addCoverLog,
      '$_startingLog$songId$_closingQuoteLog',
      _addCoverFailedMessage,
      (SongDataSource dataSource) => dataSource.addCover(songId: songId, cover: cover),
    );
  }

  @override
  Future<Result<void>> updateCover({
    required String songId,
    required String coverId,
    required List<int> audioBytes,
    String? notes,
  }) {
    final CoverModel cover = CoverModel(
      id: coverId,
      timestamp: DateTime.now().millisecondsSinceEpoch,
      audioBytes: audioBytes,
      notes: notes,
    );
    return _run(
      _updateCoverLog,
      '$_startingLog$songId$_coverIdLog$coverId$_closingQuoteLog',
      _updateCoverFailedMessage,
      (SongDataSource dataSource) => dataSource.updateCover(songId: songId, cover: cover),
    );
  }

  @override
  Future<Result<void>> deleteCover({required String songId, required String coverId}) {
    return _run(
      _deleteCoverLog,
      '$_startingLog$songId$_coverIdLog$coverId$_closingQuoteLog',
      _deleteCoverFailedMessage,
      (SongDataSource dataSource) => dataSource.deleteCover(songId: songId, coverId: coverId),
    );
  }
}
