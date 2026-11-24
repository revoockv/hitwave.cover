import 'dart:async';

import 'package:flutter/foundation.dart' show ValueListenable;
import 'package:flutter/material.dart';
import 'package:watch_it/watch_it.dart';

import '../../../../core/domain/entities/result.dart';
import '../../../../core/domain/entities/result_state.dart';
import '../../../../core/presentation/l10n/app_translations.dart';
import '../../../../core/presentation/theme.dart';
import '../../domain/entities/instrument.dart';
import '../../domain/entities/tuner_failure.dart';
import '../../domain/entities/tuner_reading.dart';
import '../../domain/entities/tuner_state.dart';
import '../controllers/tuner_controller.dart';
import '../di/tuner_getters.dart';
import '../l10n/tuner_texts.dart';
import 'instrument_strings_widget.dart';
import 'tuner_meter_widget.dart';

/// The tuner: the instrument to choose, the strings, the note heard and how far it is.
///
/// Listens to the microphone while it is shown and frees it when it goes away.
final class TunerWidget extends WatchingWidget {
  /// Creates a [TunerWidget].
  const TunerWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final Translations t = context.t;
    final TunerController tunerController = createOnce(TunerController.new, dispose: _disposeTunerController);
    callOnceAfterThisBuild((BuildContext context) => _start(tunerController));
    final Instrument instrument = watch(tunerController.instrumentController).value;
    final ResultState<void, TunerFailure> startState = watch(tunerController.startStateController).value;

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(AppTheme.spacingLarge),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: AppTheme.maxContentWidth),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Wrap(
                alignment: WrapAlignment.center,
                spacing: AppTheme.spacingSmall,
                runSpacing: AppTheme.spacingSmall,
                children: <Widget>[
                  for (final Instrument choice in Instrument.values)
                    ChoiceChip(
                      label: Text(choice.label(t)),
                      selected: choice == instrument,
                      onSelected: (bool selected) => tunerController.choose(choice),
                    ),
                ],
              ),
              const SizedBox(height: AppTheme.spacingExtraLarge),
              switch (startState) {
                FailureResultState<void, TunerFailure>(:final TunerFailure failure) => Column(
                  children: <Widget>[
                    Text(failure.text(t), textAlign: TextAlign.center),
                    const SizedBox(height: AppTheme.spacingMedium),
                    FilledButton(onPressed: () => _start(tunerController), child: Text(t.tuner.retry)),
                  ],
                ),
                _ => _TunerDisplayWidget(instrument: instrument),
              },
            ],
          ),
        ),
      ),
    );
  }

  /// Starts the tuner and records the outcome; ignored while a start runs.
  Future<void> _start(TunerController tunerController) async {
    final ValueNotifier<ResultState<void, TunerFailure>> startStateController = tunerController.startStateController;
    if (startStateController.value.isLoading) return;
    startStateController.value = ResultState.loading;
    final Result<void, TunerFailure> result = await startTunerUseCase();
    if (tunerController.isDisposed) return;
    startStateController.value = ResultState.of(result);
  }

  /// Frees the microphone when the tuner goes away.
  static void _disposeTunerController(TunerController tunerController) {
    unawaited(stopTunerUseCase());
    tunerController.dispose();
  }
}

/// The part that follows the heard pitch: only it rebuilds several times a second.
final class _TunerDisplayWidget extends WatchingWidget {
  final Instrument instrument;

  const _TunerDisplayWidget({required this.instrument});

  @override
  Widget build(BuildContext context) {
    final Translations t = context.t;
    final double? hertz = watchPropertyValue(_hertzOf, target: watchTunerUseCase());
    final TunerReading? reading = hertz == null ? null : TunerReading.of(hertz, instrument);

    return Column(
      children: <Widget>[
        TunerMeterWidget(
          reading: reading,
          idleText: t.tuner.playString,
          inTuneText: t.tuner.inTune,
          tuneUpText: t.tuner.tuneUp,
          tuneDownText: t.tuner.tuneDown,
          hertzText: _hertzText(t),
          centsText: _centsText(t),
        ),
        const SizedBox(height: AppTheme.spacingLarge),
        InstrumentStringsWidget(strings: instrument.strings, target: reading?.target),
      ],
    );
  }

  static double? _hertzOf(ValueListenable<TunerState> tuner) => switch (tuner.value) {
    ListeningTunerState(:final double? hertz) => hertz,
    OffTunerState() => null,
  };

  static String Function(String value) _hertzText(Translations t) =>
      (String value) => t.tuner.hertz(value: value);

  static String Function(String value) _centsText(Translations t) =>
      (String value) => t.tuner.cents(value: value);
}
