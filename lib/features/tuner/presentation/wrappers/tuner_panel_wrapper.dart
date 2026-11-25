import 'package:flutter/foundation.dart' show ValueListenable;
import 'package:flutter/material.dart';
import 'package:watch_it/watch_it.dart';

import '../../../../core/domain/entities/result_state.dart';
import '../../../../core/presentation/l10n/app_translations.dart';
import '../../domain/entities/instrument.dart';
import '../../domain/entities/tuner_failure.dart';
import '../controllers/tuner_controller.dart';
import '../l10n/tuner_texts.dart';
import '../widgets/tuner_panel_widget.dart';
import 'tuner_reading_wrapper.dart';

/// Gives [TunerPanelWidget] the chosen instrument and the failure of opening the microphone, from the page's
/// [TunerController]; the fast reading has a wrapper of its own.
final class TunerPanelWrapper extends WatchingWidget {
  /// The instrument and the start progress, owned by the page.
  final TunerController tunerController;

  /// Called by the retry button; the page starts the tuner again.
  final VoidCallback onRetryPressed;

  /// Creates the wrapper.
  const TunerPanelWrapper({required this.tunerController, required this.onRetryPressed, super.key});

  @override
  Widget build(BuildContext context) {
    final Translations t = context.t;
    final Instrument instrument = watch(tunerController.instrumentController).value;
    final TunerFailure? failure = watchPropertyValue(_failureOf, target: tunerController.startStateController);
    return TunerPanelWidget(
      instrument: instrument,
      instrumentLabelOf: t.instrumentLabel,
      failureText: failure?.text(t),
      retryLabel: t.tuner.retry,
      reading: TunerReadingWrapper(instrument: instrument, texts: t.tunerMeter),
      onInstrumentSelected: tunerController.choose,
      onRetryPressed: onRetryPressed,
    );
  }

  static TunerFailure? _failureOf(ValueListenable<ResultState<void, TunerFailure>> state) => switch (state.value) {
    FailureResultState<void, TunerFailure>(:final TunerFailure failure) => failure,
    _ => null,
  };
}
