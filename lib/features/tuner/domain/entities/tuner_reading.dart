import 'instrument.dart';
import 'note.dart';

/// What the tuner shows for one heard pitch: the note to tune to and how far the pitch is from it.
final class TunerReading {
  /// Cents from the note that still count as in tune.
  static const double inTuneCents = 5;

  /// The heard frequency in hertz.
  final double hertz;

  /// The note to tune to: the nearest string of the instrument, or the nearest note in chromatic mode.
  final Note target;

  /// How far [hertz] is from [target]: below 0 tune up, above 0 tune down.
  final double cents;

  /// Creates a [TunerReading].
  const TunerReading({required this.hertz, required this.target, required this.cents});

  /// The reading of [hertz] on [instrument]: the string whose note is nearest (in cents) is the target.
  factory TunerReading.of(double hertz, Instrument instrument) {
    Note target = instrument.strings.isEmpty ? Note.nearest(hertz) : instrument.strings.first;
    for (final Note string in instrument.strings) {
      if (string.centsOf(hertz).abs() < target.centsOf(hertz).abs()) target = string;
    }
    return TunerReading(hertz: hertz, target: target, cents: target.centsOf(hertz));
  }

  /// Whether the pitch is close enough to [target].
  bool get isInTune => cents.abs() <= inTuneCents;
}
