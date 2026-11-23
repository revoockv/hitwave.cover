import 'package:flutter/foundation.dart' show ValueListenable;

import '../entities/recorder_state.dart';
import '../repositories/recordings_repository.dart';

/// Use case that exposes the recorder: idle, or recording with the time and the input level.
final class WatchRecorderUseCase {
  final RecordingsRepository _repository;

  /// Creates a [WatchRecorderUseCase].
  WatchRecorderUseCase(this._repository);

  /// Returns the recorder state.
  ValueListenable<RecorderState> call() {
    return _repository.watchRecorder();
  }
}
