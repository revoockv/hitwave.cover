import 'package:flutter/foundation.dart' show ValueListenable;

import '../repositories/recordings_repository.dart';

/// Use case that exposes which take the audio engine is enhancing now, so its card alone shows
/// the progress.
final class WatchEnhancingRecordingUseCase {
  final RecordingsRepository _repository;

  /// Creates a [WatchEnhancingRecordingUseCase].
  WatchEnhancingRecordingUseCase(this._repository);

  /// Returns the id of the take being enhanced; `null` when nothing is.
  ValueListenable<String?> call() {
    return _repository.watchEnhancingRecording();
  }
}
