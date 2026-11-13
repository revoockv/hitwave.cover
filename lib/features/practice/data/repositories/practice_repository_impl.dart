import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:logger/logger.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/domain/entities/disposable_resource.dart';
import '../../../../core/domain/entities/result.dart';
import '../../../song/domain/entities/song_id_change.dart';
import '../../../song/domain/repositories/song_repository.dart';
import '../../domain/entities/practice_session.dart';
import '../../domain/repositories/practice_repository.dart';
import '../data_sources/hive_practice_service.dart';
import '../models/practice_session_model.dart';
import '../../domain/entities/practice_failure.dart';

/// [PracticeRepository] on a Hive box and a clock.
///
/// A session shorter than [_minimumLength] (a start pressed by mistake) is not kept.
final class PracticeRepositoryImpl implements PracticeRepository, DisposableResource {
  static const Duration _minimumLength = Duration(seconds: 10);

  static const String _importLog = 'ImportPracticeSessions: ';
  static const String _clearLog = 'ClearPractice: ';
  static const String _stopLog = 'StopPractice: ';
  static const String _songIdLog = 'PracticeSongIdChange: ';
  static const String _successLog = 'success — ';
  static const String _failureLog = 'failure — ';
  static const String _secondsLog = 's';
  static const String _arrowLog = ' → ';
  static const String _deletedLog = 'deleted ';

  static const Uuid _uuid = Uuid();

  final HivePracticeService _store;
  final SongRepository _songs;
  final Logger _logger;
  final DateTime Function() _now;

  final ValueNotifier<List<PracticeSession>> _sessions = ValueNotifier<List<PracticeSession>>(
    const <PracticeSession>[],
  );
  final Map<String, PracticeSessionModel> _models = <String, PracticeSessionModel>{};

  StreamSubscription<SongIdChange>? _songIdChanges;
  String? _activeSongId;
  DateTime? _activeSince;

  /// Creates a [PracticeRepositoryImpl]; [now] is replaced in tests.
  PracticeRepositoryImpl({required this._store, required this._songs, required this._logger, DateTime Function()? now})
    : _now = now ?? DateTime.now;

  /// Loads the sessions and follows the song ids; returns this for `registerSingletonAsync`.
  PracticeRepositoryImpl init() {
    for (final PracticeSessionModel model in _store.readAll()) {
      _models[model.id] = model;
    }
    _publish();
    _songIdChanges = _songs.watchSongIdChanges().listen(_onSongIdChanged);
    return this;
  }

  /// Stops following the song ids and releases the state.
  @override
  Future<void> dispose() async {
    await _songIdChanges?.cancel();
    _sessions.dispose();
  }

  @override
  ValueListenable<List<PracticeSession>> watchSessions() => _sessions;

  @override
  Future<Result<void, PracticeFailure>> startPractice(String songId) async {
    if (_activeSongId == songId) return Result.ok;
    final Result<void, PracticeFailure> stopped = await stopPractice();
    _activeSongId = songId;
    _activeSince = _now();
    return stopped;
  }

  @override
  Future<Result<void, PracticeFailure>> stopPractice() async {
    final String? songId = _activeSongId;
    final DateTime? since = _activeSince;
    _activeSongId = null;
    _activeSince = null;
    if (songId == null || since == null) return Result.ok;

    final Duration length = _now().difference(since);
    if (length < _minimumLength) return Result.ok;
    try {
      final PracticeSessionModel model = PracticeSessionModel(
        id: _uuid.v4(),
        songId: songId,
        startedAt: since,
        seconds: length.inSeconds,
      );
      await _store.put(model);
      _models[model.id] = model;
      _publish();
      _logger.i('$_stopLog$_successLog$songId ${length.inSeconds}$_secondsLog');
      return Result.ok;
    } on Exception catch (e) {
      _logger.e('$_stopLog$_failureLog$e');
      return const Result.failure(PracticeFailure.saveSession);
    }
  }

  @override
  Future<Result<void, PracticeFailure>> importSessions(List<PracticeSession> sessions) async {
    try {
      for (final PracticeSession session in sessions) {
        if (_models.containsKey(session.id)) continue;
        final PracticeSessionModel model = PracticeSessionModel.fromEntity(session);
        await _store.put(model);
        _models[model.id] = model;
      }
      _publish();
      return Result.ok;
    } on Exception catch (e) {
      _logger.e('$_importLog$_failureLog$e');
      return const Result.failure(PracticeFailure.importSessions);
    }
  }

  @override
  Future<Result<void, PracticeFailure>> clearSessions() async {
    try {
      await _store.deleteAll(List<String>.of(_models.keys));
      _models.clear();
      _publish();
      return Result.ok;
    } on Exception catch (e) {
      _logger.e('$_clearLog$_failureLog$e');
      return const Result.failure(PracticeFailure.clear);
    }
  }

  Future<void> _onSongIdChanged(SongIdChange change) async {
    try {
      switch (change) {
        case SongMovedIdChange(:final String fromId, :final String toId):
          if (_activeSongId == fromId) _activeSongId = toId;
          for (final PracticeSessionModel model in _sessionsOf(fromId)) {
            final PracticeSessionModel moved = model.withSongId(toId);
            await _store.put(moved);
            _models[moved.id] = moved;
          }
          _logger.i('$_songIdLog$fromId$_arrowLog$toId');
        case SongDeletedIdChange(:final String songId):
          if (_activeSongId == songId) {
            _activeSongId = null;
            _activeSince = null;
          }
          final List<String> ids = _sessionsOf(songId).map(_idOf).toList();
          await _store.deleteAll(ids);
          ids.forEach(_models.remove);
          _logger.i('$_songIdLog$_deletedLog$songId');
      }
      _publish();
    } on Exception catch (e) {
      _logger.e('$_songIdLog$_failureLog$e');
    }
  }

  List<PracticeSessionModel> _sessionsOf(String songId) =>
      _models.values.where((PracticeSessionModel model) => model.songId == songId).toList();

  static String _idOf(PracticeSessionModel model) => model.id;

  void _publish() {
    final List<PracticeSession> sessions = _models.values.map(_entity).toList()
      ..sort((PracticeSession a, PracticeSession b) => b.startedAt.compareTo(a.startedAt));
    _sessions.value = sessions;
  }

  static PracticeSession _entity(PracticeSessionModel model) => model.toEntity();
}
