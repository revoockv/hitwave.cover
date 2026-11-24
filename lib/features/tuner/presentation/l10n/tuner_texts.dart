import '../../../../core/presentation/l10n/app_translations.dart';
import '../../domain/entities/instrument.dart';
import '../../domain/entities/tuner_failure.dart';

/// The text of a [TunerFailure] shown to the user.
extension TunerFailureText on TunerFailure {
  /// The text of this failure in the language of [t].
  String text(Translations t) => switch (this) {
    TunerFailure.microphonePermission => t.tuner.failure.microphonePermission,
    TunerFailure.start => t.tuner.failure.start,
  };
}

/// The name of an [Instrument] shown to the user.
extension InstrumentLabel on Instrument {
  /// The name of this instrument in the language of [t].
  String label(Translations t) => switch (this) {
    Instrument.guitar => t.tuner.instruments.guitar,
    Instrument.ukulele => t.tuner.instruments.ukulele,
    Instrument.bass => t.tuner.instruments.bass,
    Instrument.violin => t.tuner.instruments.violin,
    Instrument.chromatic => t.tuner.instruments.chromatic,
  };
}
