import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:logger/logger.dart';

import '../../../../core/domain/entities/disposable_resource.dart';
import '../../../../core/domain/entities/result.dart';
import '../../domain/entities/cover.dart';
import '../../domain/entities/song.dart';
import '../../domain/entities/song_id_change.dart';
import '../../domain/repositories/song_repository.dart';
import '../data_sources/song_data_source.dart';
import '../models/cover_model.dart';
import '../models/song_model.dart';
import '../../domain/entities/song_failure.dart';

/// [SongRepository] on the songs of this device (Hive).
///
/// Subscribes to the songs of the [SongDataSource] in [init] and keeps them in a private
/// [ValueNotifier], exposed as [ValueListenable].
final class SongRepositoryImpl implements SongRepository, DisposableResource {
  static const String _newDocumentId = '';

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
  static const String _addCoverLog = 'AddCover';
  static const String _updateCoverLog = 'UpdateCover';
  static const String _deleteCoverLog = 'DeleteCover';

  static const String _startingLog = ': starting for songId="';
  static const String _startingNameLog = ': starting for name="';
  static const String _startingCountLog = ': starting for songs: ';
  static const String _successLog = ': success';
  static const String _coverIdLog = '", coverId="';
  static const String _closingQuoteLog = '"';
  static const String _failureLog = ': failure — ';

  final SongDataSource _dataSource;
  final Logger _logger;

  final ValueNotifier<List<Song>> _songs = ValueNotifier<List<Song>>(const <Song>[]);

  final StreamController<SongIdChange> _songIdChanges = StreamController<SongIdChange>.broadcast();

  StreamSubscription<List<SongModel>>? _subscription;

  /// Creates a new [SongRepositoryImpl] on [_dataSource].
  SongRepositoryImpl({required this._dataSource, required this._logger});

  /// Subscribes to the songs; returns this for `registerSingletonAsync`.
  Future<SongRepositoryImpl> init() async {
    _subscription = _dataSource.watchSongs().listen(_onSongModels, onError: _onSongsError);
    return this;
  }

  /// Cancels the subscription and releases the state.
  @override
  Future<void> dispose() async {
    await _subscription?.cancel();
    _subscription = null;
    _songs.dispose();
    await _songIdChanges.close();
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
    _songs.value = await Future.wait(models.map(_toSong));
  }

  Future<Song> _toSong(SongModel model) async {
    if (model.coverIds.isEmpty) {
      return model.toEntity(covers: const <Cover>[]);
    }

    final List<CoverModel> coverModels = await _dataSource.getCovers(model.id);
    return model.toEntity(covers: coverModels.map(_toCover).toList());
  }

  Cover _toCover(CoverModel model) => model.toEntity();

  /// Runs [operation] on the data source and logs it as [logName].
  Future<Result<void, SongFailure>> _run(
    String logName,
    String startDetails,
    SongFailure failure,
    Future<void> Function(SongDataSource dataSource) operation,
  ) async {
    _logger.i('$logName$startDetails');
    try {
      await operation(_dataSource);
      _logger.i('$logName$_successLog');
      return Result.ok;
    } on Exception catch (e) {
      _logger.e('$logName$_failureLog$e');
      return Result.failure(failure);
    }
  }

  @override
  Future<Result<void, SongFailure>> addSong({
    required String author,
    required String name,
    String? album,
    required String lyrics,
  }) {
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
      SongFailure.addSong,
      (SongDataSource dataSource) => dataSource.addSong(song),
    );
  }

  @override
  Future<Result<List<String>, SongFailure>> addSongs(List<Song> songs) async {
    final List<String> ids = <String>[];
    final Result<void, SongFailure> result = await _run(
      _addSongsLog,
      '$_startingCountLog${songs.length}',
      SongFailure.addSongs,
      (SongDataSource dataSource) async {
        for (final Song song in songs) {
          ids.add(await dataSource.addSong(SongModel.fromEntity(song)));
        }
      },
    );
    return result.when(success: (_) => Result.success(ids), failure: Result<List<String>, SongFailure>.failure);
  }

  @override
  Stream<SongIdChange> watchSongIdChanges() => _songIdChanges.stream;

  @override
  Future<Result<void, SongFailure>> updateSong({
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
      SongFailure.updateSong,
      (SongDataSource dataSource) => dataSource.updateSong(song),
    );
  }

  @override
  Future<Result<void, SongFailure>> updateSongScrollSpeed({required String songId, required double speed}) {
    return _run(
      _updateSpeedLog,
      '$_startingLog$songId$_speedLog$speed',
      SongFailure.updateSpeed,
      (SongDataSource dataSource) => dataSource.updateSongScrollSpeed(songId: songId, speed: speed),
    );
  }

  @override
  Future<Result<void, SongFailure>> updateSongLeadIn({required String songId, required double leadIn}) {
    return _run(
      _updateLeadInLog,
      '$_startingLog$songId$_leadInLog$leadIn',
      SongFailure.updateLeadIn,
      (SongDataSource dataSource) => dataSource.updateSongLeadIn(songId: songId, leadIn: leadIn),
    );
  }

  @override
  Future<Result<void, SongFailure>> updateSongLyrics({required String songId, required String lyrics}) {
    return _run(
      _updateLyricsLog,
      '$_startingLog$songId$_closingQuoteLog',
      SongFailure.updateLyrics,
      (SongDataSource dataSource) => dataSource.updateSongLyrics(songId: songId, lyrics: lyrics),
    );
  }

  @override
  Future<Result<void, SongFailure>> deleteSong({required String songId}) async {
    Song? deleted;
    for (final Song song in _songs.value) {
      if (song.id == songId) deleted = song;
    }
    final Result<void, SongFailure> result = await _run(
      _deleteSongLog,
      '$_startingLog$songId$_closingQuoteLog',
      SongFailure.deleteSong,
      (SongDataSource dataSource) => dataSource.deleteSong(songId),
    );
    if (result.isSuccess) {
      _songIdChanges.add(SongDeletedIdChange(songId, author: deleted?.author, name: deleted?.name));
    }
    return result;
  }

  @override
  Future<Result<void, SongFailure>> deleteAllSongs() async {
    for (final Song song in List<Song>.of(_songs.value)) {
      final Result<void, SongFailure> deleted = await deleteSong(songId: song.id);
      if (deleted.isFailure) return deleted;
    }
    return Result.ok;
  }

  @override
  Future<Result<void, SongFailure>> addCover({required String songId, required List<int> audioBytes, String? notes}) {
    final CoverModel cover = CoverModel(
      id: _newDocumentId,
      timestamp: DateTime.now().millisecondsSinceEpoch,
      audioBytes: audioBytes,
      notes: notes,
    );
    return _run(
      _addCoverLog,
      '$_startingLog$songId$_closingQuoteLog',
      SongFailure.addCover,
      (SongDataSource dataSource) => dataSource.addCover(songId: songId, cover: cover),
    );
  }

  @override
  Future<Result<void, SongFailure>> updateCover({
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
      SongFailure.updateCover,
      (SongDataSource dataSource) => dataSource.updateCover(songId: songId, cover: cover),
    );
  }

  @override
  Future<Result<void, SongFailure>> deleteCover({required String songId, required String coverId}) {
    return _run(
      _deleteCoverLog,
      '$_startingLog$songId$_coverIdLog$coverId$_closingQuoteLog',
      SongFailure.deleteCover,
      (SongDataSource dataSource) => dataSource.deleteCover(songId: songId, coverId: coverId),
    );
  }
}
