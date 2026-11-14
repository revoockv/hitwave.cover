import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:logger/logger.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/domain/entities/disposable_resource.dart';
import '../../../../core/domain/entities/result.dart';
import '../../../recordings/domain/entities/recording.dart';
import '../../../recordings/domain/repositories/recordings_repository.dart';
import '../../../song/domain/entities/song_id_change.dart';
import '../../../song/domain/repositories/song_repository.dart';
import '../../domain/entities/practice_session.dart';
import '../../domain/repositories/practice_repository.dart';
import '../data_sources/hive_practice_service.dart';
import '../models/practice_session_model.dart';
import '../../domain/entities/practice_failure.dart';

/// [PracticeRepository] on a Hive box and a clock.
///
/// A session shorter than [_minimumLength] (a start pressed by mistake) is not kept. A session
/// during which a cover was recorded goes away with that cover, so a deleted cover leaves nothing
/// in the statistics.
final class PracticeRepositoryImpl implements PracticeRepository, DisposableResource {
  static const Duration _minimumLength = Duration(seconds: 10);

  /// A take starts a moment before its session and is stopped just before it ends.
  static const Duration _takeSlack = Duration(seconds: 5);
  static const String _coverLog = 'PracticeCoverDeleted: ';

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
  final RecordingsRepository _recordings;
  final Logger _logger;
  final DateTime Function() _now;

  final ValueNotifier<List<PracticeSession>> _sessions = ValueNotifier<List<PracticeSession>>(
    const <PracticeSession>[],
  );
  final Map<String, PracticeSessionModel> _models = <String, PracticeSessionModel>{};

  StreamSubscription<SongIdChange>? _songIdChanges;
  StreamSubscription<String>? _coverDeletions;

  /// Song and start of every cover seen, by id: a deleted cover is gone from the list by the time
  /// its deletion arrives.
  final Map<String, ({String songId, DateTime recordedAt})> _covers =
      <String, ({String songId, DateTime recordedAt})>{};
  String? _activeSongId;
  DateTime? _activeSince;

  /// Creates a [PracticeRepositoryImpl]; [now] is replaced in tests.
  PracticeRepositoryImpl({
    required this._store,
    required this._songs,
    required this._recordings,
    required this._logger,
    DateTime Function()? now,
  }) : _now = now ?? DateTime.now;

  /// Loads the sessions and follows the song ids; returns this for `registerSingletonAsync`.
  PracticeRepositoryImpl init() {
    for (final PracticeSessionModel model in _store.readAll()) {
      _models[model.id] = model;
    }
    _publish();
    _songIdChanges = _songs.watchSongIdChanges().listen(_onSongIdChanged);
    _rememberCovers();
    _recordings.watchRecordings().addListener(_rememberCovers);
    _coverDeletions = _recordings.watchRecordingDeletions().listen(_onCoverDeleted);
    return this;
  }

  /// Stops following the song ids and releases the state.
  @override
  Future<void> dispose() async {
    await _songIdChanges?.cancel();
    await _coverDeletions?.cancel();
    _recordings.watchRecordings().removeListener(_rememberCovers);
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

  void _rememberCovers() {
    for (final Recording recording in _recordings.watchRecordings().value) {
      _covers[recording.id] = (songId: recording.songId, recordedAt: recording.recordedAt);
    }
  }

  /// Forgets the session of the song during which the deleted cover was recorded.
  Future<void> _onCoverDeleted(String recordingId) async {
    final ({String songId, DateTime recordedAt})? cover = _covers.remove(recordingId);
    if (cover == null) return;
    try {
      final List<String> ids = <String>[
        for (final PracticeSessionModel model in _sessionsOf(cover.songId))
          if (!cover.recordedAt.isBefore(model.startedAt.subtract(_takeSlack)) &&
              !cover.recordedAt.isAfter(model.startedAt.add(Duration(seconds: model.seconds) + _takeSlack)))
            model.id,
      ];
      if (ids.isEmpty) return;
      await _store.deleteAll(ids);
      ids.forEach(_models.remove);
      _publish();
      _logger.i('$_coverLog$_successLog$recordingId$_arrowLog${ids.length}');
    } on Exception catch (e) {
      _logger.e('$_coverLog$_failureLog$e');
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
