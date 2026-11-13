import 'package:flutter/foundation.dart' show ValueListenable;

import '../entities/usage_history.dart';
import '../repositories/history_repository.dart';

/// Use case that exposes when songs were opened and covers played.
final class WatchUsageHistoryUseCase {
  final HistoryRepository _repository;

  /// Creates a [WatchUsageHistoryUseCase].
  WatchUsageHistoryUseCase(this._repository);

  /// Returns the history.
  ValueListenable<UsageHistory> call() {
    return _repository.watchHistory();
  }
}
