import 'package:flutter/foundation.dart' show ValueListenable;

import '../../../../core/domain/entities/result.dart';
import '../entities/usage_history.dart';
import '../entities/history_failure.dart';

/// Remembers when songs were opened and covers played, only on this device.
///
/// The openings follow their song when its id changes and are forgotten with it.
abstract interface class HistoryRepository {
  /// The history.
  ValueListenable<UsageHistory> watchHistory();

  /// Remembers that [songId] was opened now.
  Future<Result<void, HistoryFailure>> markSongOpened(String songId);

  /// Remembers that the cover [recordingId] was played now.
  Future<Result<void, HistoryFailure>> markCoverPlayed(String recordingId);

  /// Adds the history of another device; the later time of every song and cover wins.
  Future<Result<void, HistoryFailure>> importHistory(UsageHistory history);
}
