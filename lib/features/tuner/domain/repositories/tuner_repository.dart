import 'package:flutter/foundation.dart' show ValueListenable;

import '../../../../core/domain/entities/result.dart';
import '../entities/tuner_failure.dart';
import '../entities/tuner_state.dart';

/// The tuner: listens to the microphone and tells the pitch it hears.
abstract interface class TunerRepository {
  /// The tuner state, updated several times a second while listening.
  ValueListenable<TunerState> watchTuner();

  /// Starts listening; does nothing when it already listens.
  Future<Result<void, TunerFailure>> start();

  /// Stops listening and frees the microphone.
  Future<void> stop();
}
