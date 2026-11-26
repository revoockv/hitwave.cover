import 'package:flutter/foundation.dart' show ValueListenable;
import 'package:flutter/material.dart';
import 'package:watch_it/watch_it.dart';

import '../../../../core/presentation/theme.dart';
import '../../domain/entities/instrument.dart';
import '../../domain/entities/tuner_reading.dart';
import '../../domain/entities/tuner_state.dart';
import '../di/tuner_getters.dart';
import '../widgets/instrument_strings_widget.dart';
import '../widgets/tuner_meter_widget.dart';

/// Follows the heard pitch — it changes several times a second, so only this wrapper rebuilds with it — and gives
/// the meter and the strings the reading on [instrument].
final class TunerReadingWrapper extends WatchingWidget {
  /// The instrument whose strings the tuner aims at.
  final Instrument instrument;

  /// The texts of the meter.
  final TunerMeterTexts texts;

  /// Creates the wrapper.
  const TunerReadingWrapper({required this.instrument, required this.texts, super.key});

  @override
  Widget build(BuildContext context) {
    final double? hertz = watchPropertyValue(_hertzOf, target: watchTunerUseCase());
    final TunerReading? reading = hertz == null ? null : TunerReading.of(hertz, instrument);
    return Column(
      children: <Widget>[
        TunerMeterWidget(reading: reading, texts: texts),
        const SizedBox(height: AppTheme.spacingLarge),
        InstrumentStringsWidget(strings: instrument.strings, target: reading?.target),
      ],
    );
  }

  static double? _hertzOf(ValueListenable<TunerState> tuner) => switch (tuner.value) {
    ListeningTunerState(:final double? hertz) => hertz,
    OffTunerState() => null,
  };
}
