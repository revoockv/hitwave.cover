import 'dart:typed_data';

import 'yin_pitch_detector.dart';

/// Turns 16-bit little-endian mono PCM, chunk by chunk, into pitches: averages every [decimation]
/// samples, keeps the last [YinPitchDetector.windowSize] of them in a ring and asks the detector
/// every [hopSize] new samples.
final class PcmPitchFramer {
  static const double _fullScale = 32768;
  static const int _bitsPerByte = 8;
  static const int _sampleBits = 16;

  final YinPitchDetector _detector;

  /// Input samples averaged into one analyzed sample.
  final int decimation;

  /// Analyzed samples between two pitches.
  final int hopSize;

  final Float64List _ring;
  final Float64List _window;
  int _written = 0;
  int _sinceLast = 0;
  double _sum = 0;
  int _summed = 0;
  int? _lowByte;

  /// Creates a framer that feeds [detector].
  PcmPitchFramer(YinPitchDetector detector, {required this.decimation, required this.hopSize})
    : _detector = detector,
      _ring = Float64List(detector.windowSize),
      _window = Float64List(detector.windowSize);

  /// The pitches the samples of [chunk] completed, oldest first (`null` for a piece without a clear pitch).
  List<double?> add(Uint8List chunk) {
    final List<double?> pitches = <double?>[];
    for (final int byte in chunk) {
      final int? low = _lowByte;
      if (low == null) {
        _lowByte = byte;
        continue;
      }
      _lowByte = null;
      _sum += (byte << _bitsPerByte | low).toSigned(_sampleBits) / _fullScale;
      if (++_summed < decimation) continue;
      _ring[_written++ % _ring.length] = _sum / decimation;
      _sum = 0;
      _summed = 0;
      if (_written >= _ring.length && ++_sinceLast >= hopSize) {
        _sinceLast = 0;
        pitches.add(_detector.detect(_unrolled()));
      }
    }
    return pitches;
  }

  /// The ring from its oldest sample to its newest.
  Float64List _unrolled() {
    final int oldest = _written % _ring.length;
    _window.setRange(0, _ring.length - oldest, _ring, oldest);
    _window.setRange(_ring.length - oldest, _ring.length, _ring);
    return _window;
  }
}
