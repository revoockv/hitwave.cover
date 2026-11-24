import 'dart:math' as math;
import 'dart:typed_data';

/// Finds the pitch of a short piece of sound with the YIN algorithm (de Cheveigné and Kawahara, 2002).
///
/// Works on mono samples from -1 to 1; covers 30–1500 Hz, from the low B of a five-string bass to
/// the high strings of a violin.
final class YinPitchDetector {
  static const double _minHertz = 30;
  static const double _maxHertz = 1500;

  /// The highest normalized difference that still counts as a period (YIN's absolute threshold).
  static const double _threshold = 0.15;

  /// Root mean square below which the piece is silence.
  static const double _silenceRms = 0.008;

  /// The sample rate of the pieces, in hertz.
  final double sampleRate;

  /// Creates a detector for pieces sampled at [sampleRate].
  const YinPitchDetector({required this.sampleRate});

  /// The fewest samples a piece needs: two periods of the lowest pitch.
  int get windowSize => (2 * sampleRate / _minHertz).ceil();

  /// The pitch of [samples] in hertz, or `null` when there is no clear one (silence, noise).
  double? detect(Float64List samples) {
    final int maxLag = math.min((sampleRate / _minHertz).ceil(), samples.length ~/ 2);
    final int minLag = math.max(2, (sampleRate / _maxHertz).floor());
    final int length = samples.length - maxLag;
    if (length <= 0 || _rms(samples) < _silenceRms) return null;

    final Float64List difference = Float64List(maxLag + 1);
    for (int lag = 1; lag <= maxLag; lag++) {
      double sum = 0;
      for (int i = 0; i < length; i++) {
        final double delta = samples[i] - samples[i + lag];
        sum += delta * delta;
      }
      difference[lag] = sum;
    }

    // Cumulative mean normalized difference: 1 at lag 0, dips toward 0 at the period.
    final Float64List normalized = Float64List(maxLag + 1)..[0] = 1;
    double running = 0;
    for (int lag = 1; lag <= maxLag; lag++) {
      running += difference[lag];
      normalized[lag] = running == 0 ? 1 : difference[lag] * lag / running;
    }

    for (int lag = minLag; lag < maxLag; lag++) {
      if (normalized[lag] >= _threshold) continue;
      while (lag + 1 < maxLag && normalized[lag + 1] < normalized[lag]) {
        lag++;
      }
      // The raw difference is a parabola near its minimum; the normalized one is bent by the running mean.
      return sampleRate / _refine(difference, lag);
    }
    return null;
  }

  /// The lag of the minimum between whole samples (parabolic interpolation).
  static double _refine(Float64List difference, int lag) {
    if (lag < 1 || lag + 1 >= difference.length) return lag.toDouble();
    final double before = difference[lag - 1];
    final double at = difference[lag];
    final double after = difference[lag + 1];
    final double bend = before - 2 * at + after;
    return bend == 0 ? lag.toDouble() : lag + (before - after) / (2 * bend);
  }

  static double _rms(Float64List samples) {
    double sum = 0;
    for (final double sample in samples) {
      sum += sample * sample;
    }
    return math.sqrt(sum / samples.length);
  }
}
