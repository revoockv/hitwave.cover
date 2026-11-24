/// State of the tuner.
sealed class TunerState {
  const TunerState();

  /// The tuner is off.
  static const TunerState off = OffTunerState();
}

/// The tuner is off: the microphone is not used.
final class OffTunerState extends TunerState {
  /// Creates an [OffTunerState].
  const OffTunerState();
}

/// The tuner listens to the microphone.
final class ListeningTunerState extends TunerState {
  /// The heard pitch in hertz; `null` while nothing clear sounds (silence, noise, a fading string).
  final double? hertz;

  /// Creates a [ListeningTunerState].
  const ListeningTunerState(this.hertz);
}
