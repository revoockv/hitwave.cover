import 'package:flutter/foundation.dart' show ValueNotifier;

import '../../../../core/domain/entities/result_state.dart';
import '../../domain/entities/instrument.dart';
import '../../domain/entities/tuner_failure.dart';

/// UI state of the tuner: the chosen instrument and the progress of starting the microphone.
///
/// Knows nothing about use cases: the owner widget starts and stops the tuner and records the
/// outcome in [startStateController].
final class TunerController {
  /// The instrument whose strings the tuner aims at.
  final ValueNotifier<Instrument> instrumentController = ValueNotifier<Instrument>(Instrument.guitar);

  /// Progress of starting the tuner; a failure is shown with a retry.
  final ValueNotifier<ResultState<void, TunerFailure>> startStateController =
      ValueNotifier<ResultState<void, TunerFailure>>(ResultState.idle);

  bool _isDisposed = false;

  /// Creates a [TunerController].
  TunerController();

  /// Whether [dispose] was called; the owner checks it after every `await`.
  bool get isDisposed => _isDisposed;

  /// Chooses [instrument].
  void choose(Instrument instrument) {
    instrumentController.value = instrument;
  }

  /// Disposes the notifiers.
  void dispose() {
    _isDisposed = true;
    instrumentController.dispose();
    startStateController.dispose();
  }
}
