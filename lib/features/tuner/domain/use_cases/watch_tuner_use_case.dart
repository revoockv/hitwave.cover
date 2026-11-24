import 'package:flutter/foundation.dart' show ValueListenable;

import '../entities/tuner_state.dart';
import '../repositories/tuner_repository.dart';

/// Use case that exposes the tuner: off, or listening with the heard pitch.
final class WatchTunerUseCase {
  final TunerRepository _repository;

  /// Creates a [WatchTunerUseCase].
  WatchTunerUseCase(this._repository);

  /// Returns the tuner state.
  ValueListenable<TunerState> call() => _repository.watchTuner();
}
