import 'package:flutter/foundation.dart' show ValueListenable;

import '../entities/sync_state.dart';
import '../repositories/sync_repository.dart';

/// Use case that exposes the state of the synchronisation.
final class WatchSyncStateUseCase {
  final SyncRepository _repository;

  /// Creates a [WatchSyncStateUseCase].
  WatchSyncStateUseCase(this._repository);

  /// Returns the state.
  ValueListenable<SyncState> call() {
    return _repository.watchSyncState();
  }
}
