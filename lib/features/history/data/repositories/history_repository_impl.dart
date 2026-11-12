import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:logger/logger.dart';

import '../../../../core/domain/entities/disposable_resource.dart';
import '../../../../core/domain/entities/result.dart';
import '../../../song/domain/entities/song_id_change.dart';
import '../../../song/domain/repositories/song_repository.dart';
import '../../domain/entities/usage_history.dart';
import '../../domain/repositories/history_repository.dart';
import '../data_sources/hive_history_service.dart';
import '../models/usage_history_model.dart';

/// [HistoryRepository] on Hive and a clock.
final class HistoryRepositoryImpl implements HistoryRepository, DisposableResource {
  static const String _saveError = 'Не вдалося запам’ятати історію';
  static const String _saveLog = 'History: failure — ';

  final HiveHistoryService _store;
  final SongRepository _songs;
  final Logger _logger;
  final DateTime Function() _now;

  final ValueNotifier<UsageHistory> _history = ValueNotifier<UsageHistory>(UsageHistory.empty);
  final Map<String, DateTime> _songsOpenedAt = <String, DateTime>{};
  final Map<String, DateTime> _coversPlayedAt = <String, DateTime>{};

  StreamSubscription<SongIdChange>? _songIdChanges;

  /// Creates a [HistoryRepositoryImpl]; [now] is replaced in tests.
  HistoryRepositoryImpl({required this._store, required this._songs, required this._logger, DateTime Function()? now})
    : _now = now ?? DateTime.now;

  /// Loads the history and follows the song ids; returns this for `registerSingletonAsync`.
  HistoryRepositoryImpl init() {
    final UsageHistoryModel stored = _store.read();
    _songsOpenedAt.addAll(stored.songsOpenedAt);
    _coversPlayedAt.addAll(stored.coversPlayedAt);
    _publish();
    _songIdChanges = _songs.watchSongIdChanges().listen(_onSongIdChanged);
    return this;
  }

  /// Stops following the song ids and releases the state.
  @override
  Future<void> dispose() async {
    await _songIdChanges?.cancel();
    _history.dispose();
  }

  @override
  ValueListenable<UsageHistory> watchHistory() => _history;

  @override
  Future<Result<void>> markSongOpened(String songId) =>
      _save(() => _store.putSongOpened(songId, _songsOpenedAt[songId] = _now()));

  @override
  Future<Result<void>> markCoverPlayed(String recordingId) =>
      _save(() => _store.putCoverPlayed(recordingId, _coversPlayedAt[recordingId] = _now()));

  @override
  Future<Result<void>> importHistory(UsageHistory history) async {
    try {
      for (final MapEntry<String, DateTime> entry in history.songsOpenedAt.entries) {
        final DateTime? current = _songsOpenedAt[entry.key];
        if (current != null && !entry.value.isAfter(current)) continue;
        _songsOpenedAt[entry.key] = entry.value;
        await _store.putSongOpened(entry.key, entry.value);
      }
      for (final MapEntry<String, DateTime> entry in history.coversPlayedAt.entries) {
        final DateTime? current = _coversPlayedAt[entry.key];
        if (current != null && !entry.value.isAfter(current)) continue;
        _coversPlayedAt[entry.key] = entry.value;
        await _store.putCoverPlayed(entry.key, entry.value);
      }
      _publish();
      return Result.ok;
    } on Exception catch (e) {
      _logger.e('$_saveLog$e');
      return const Result.failure(_saveError);
    }
  }

  Future<Result<void>> _save(Future<void> Function() write) async {
    try {
      final Future<void> written = write();
      _publish();
      await written;
      return Result.ok;
    } on Exception catch (e) {
      _logger.e('$_saveLog$e');
      return const Result.failure(_saveError);
    }
  }

  Future<void> _onSongIdChanged(SongIdChange change) async {
    try {
      switch (change) {
        case SongMovedIdChange(:final String fromId, :final String toId):
          final DateTime? openedAt = _songsOpenedAt.remove(fromId);
          if (openedAt == null) return;
          _songsOpenedAt[toId] = openedAt;
          await _store.deleteSong(fromId);
          await _store.putSongOpened(toId, openedAt);
        case SongDeletedIdChange(:final String songId):
          if (_songsOpenedAt.remove(songId) == null) return;
          await _store.deleteSong(songId);
      }
      _publish();
    } on Exception catch (e) {
      _logger.e('$_saveLog$e');
    }
  }

  void _publish() {
    _history.value = UsageHistory(
      songsOpenedAt: Map<String, DateTime>.unmodifiable(_songsOpenedAt),
      coversPlayedAt: Map<String, DateTime>.unmodifiable(_coversPlayedAt),
    );
  }
}
