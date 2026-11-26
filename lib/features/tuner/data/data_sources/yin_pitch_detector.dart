import 'dart:math' as math;
import 'dart:typed_data';

/// Finds the pitch of a short piece of sound with the YIN algorithm (de Cheveigné and Kawahara, 2002).
///
/// Works on mono samples from -1 to 1; covers 30–1500 Hz, from the low B of a five-string bass to
/// the high strings of a violin. The period is searched on the piece halved in rate (fast), then
/// refined at the full rate over the whole piece (precise: a fraction of a cent on a clean tone).
final class YinPitchDetector {
  static const double _minHertz = 30;
  static const double _maxHertz = 1500;

  /// The highest normalized difference that still counts as a period (YIN's absolute threshold): a quiet string
  /// over the room's noise dips less deep than a loud one, noise does not dip at all.
  static const double _threshold = 0.25;

  /// Root mean square below which the piece is silence (about -56 dBFS): the raw microphone, without gain, gives a
  /// string played softly at a phone's distance not much more. Whether it is a pitch is the threshold's job.
  static const double _silenceRms = 0.0015;

  /// Samples averaged into one of the coarse search.
  static const int _coarseFactor = 2;

  /// Samples of the moving average that is run twice over a piece: keeps the strings (1 % weaker at 330 Hz, 15 % at
  /// 1300 Hz, the pitch itself unchanged) and takes away most of the hiss above them.
  static const int _smoothWidth = 8;
  static const int _smoothPasses = 2;

  /// Full-rate lags around the coarse period that the refinement tries on each side.
  static const int _refineReach = 3;

  /// The sample rate of the pieces, in hertz.
  final double sampleRate;

  /// Creates a detector for pieces sampled at [sampleRate].
  const YinPitchDetector({required this.sampleRate});

  /// The fewest samples a piece needs: two periods of the lowest pitch.
  int get windowSize => (2 * sampleRate / _minHertz).ceil();

  /// The pitch of [samples] in hertz, or `null` when there is no clear one (silence, noise).
  double? detect(Float64List samples) {
    if (_rms(samples) < _silenceRms) return null;
    Float64List smooth = samples;
    for (int pass = 0; pass < _smoothPasses; pass++) {
      smooth = _movingAverage(smooth);
    }
    final double? coarseLag = _coarsePeriod(_halved(smooth), sampleRate / _coarseFactor);
    if (coarseLag == null) return null;
    return sampleRate / _refinedPeriod(smooth, coarseLag * _coarseFactor);
  }

  /// The period of [samples] in samples by YIN, or `null` when no dip goes under the threshold.
  static double? _coarsePeriod(Float64List samples, double rate) {
    final int maxLag = math.min((rate / _minHertz).ceil(), samples.length ~/ 2);
    final int minLag = math.max(2, (rate / _maxHertz).floor());
    final int length = samples.length - maxLag;
    if (length <= 0) return null;

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
    double running = 0;
    final Float64List normalized = Float64List(maxLag + 1)..[0] = 1;
    for (int lag = 1; lag <= maxLag; lag++) {
      running += difference[lag];
      normalized[lag] = running == 0 ? 1 : difference[lag] * lag / running;
    }

    for (int lag = minLag; lag < maxLag; lag++) {
      if (normalized[lag] >= _threshold) continue;
      while (lag + 1 < maxLag && normalized[lag + 1] < normalized[lag]) {
        lag++;
      }
      return _parabolaMinimum(difference[lag - 1], difference[lag], difference[lag + 1]) + lag;
    }
    return null;
  }

  /// The period near [guess] at the full rate: the raw difference over every sample the piece has for the lags
  /// around [guess], its minimum found between whole samples.
  static double _refinedPeriod(Float64List samples, double guess) {
    final int first = math.max(2, guess.round() - _refineReach);
    final int last = guess.round() + _refineReach;
    // One length for every lag, so the differences compare.
    final int length = samples.length - last - 1;
    if (length <= 0) return guess;

    final Float64List difference = Float64List(last - first + 3);
    for (int k = 0; k < difference.length; k++) {
      final int lag = first - 1 + k;
      double sum = 0;
      for (int i = 0; i < length; i++) {
        final double delta = samples[i] - samples[i + lag];
        sum += delta * delta;
      }
      difference[k] = sum;
    }

    int best = 1;
    for (int k = 2; k < difference.length - 1; k++) {
      if (difference[k] < difference[best]) best = k;
    }
    return first - 1 + best + _parabolaMinimum(difference[best - 1], difference[best], difference[best + 1]);
  }

  /// Where the parabola through three equally spaced values has its minimum, from -0.5 to 0.5 around the middle one.
  static double _parabolaMinimum(double before, double at, double after) {
    final double bend = before - 2 * at + after;
    if (bend <= 0) return 0;
    return ((before - after) / (2 * bend)).clamp(-0.5, 0.5);
  }

  /// The mean of every [_smoothWidth] neighbouring samples of [samples].
  static Float64List _movingAverage(Float64List samples) {
    final Float64List averaged = Float64List(samples.length - _smoothWidth + 1);
    double sum = 0;
    for (int i = 0; i < samples.length; i++) {
      sum += samples[i];
      if (i >= _smoothWidth) sum -= samples[i - _smoothWidth];
      if (i >= _smoothWidth - 1) averaged[i - _smoothWidth + 1] = sum / _smoothWidth;
    }
    return averaged;
  }

  /// [samples] at half the rate: every two averaged.
  static Float64List _halved(Float64List samples) {
    final Float64List halved = Float64List(samples.length ~/ _coarseFactor);
    for (int i = 0; i < halved.length; i++) {
      halved[i] = (samples[_coarseFactor * i] + samples[_coarseFactor * i + 1]) / _coarseFactor;
    }
    return halved;
  }

  static double _rms(Float64List samples) {
    double sum = 0;
    for (final double sample in samples) {
      sum += sample * sample;
    }
    return math.sqrt(sum / samples.length);
  }
}
