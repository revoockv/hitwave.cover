import 'package:flutter/foundation.dart' show ValueListenable;

import '../entities/recording.dart';
import '../repositories/recordings_repository.dart';

/// Use case that exposes every recording on the device, newest first.
final class WatchRecordingsUseCase {
  final RecordingsRepository _repository;

  /// Creates a [WatchRecordingsUseCase].
  WatchRecordingsUseCase(this._repository);

  /// Returns the recordings.
  ValueListenable<List<Recording>> call() {
    return _repository.watchRecordings();
  }
}
