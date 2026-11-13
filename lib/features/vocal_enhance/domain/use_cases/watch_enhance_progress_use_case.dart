import 'package:flutter/foundation.dart' show ValueListenable;

import '../entities/enhance_progress.dart';
import '../repositories/vocal_enhance_repository.dart';

/// Use case that exposes the step of the running enhancement as a [ValueListenable].
final class WatchEnhanceProgressUseCase {
  final VocalEnhanceRepository _repository;

  /// Creates a [WatchEnhanceProgressUseCase].
  WatchEnhanceProgressUseCase(this._repository);

  /// Returns the progress; `null` when nothing runs.
  ValueListenable<EnhanceProgress?> call() {
    return _repository.watchProgress();
  }
}
