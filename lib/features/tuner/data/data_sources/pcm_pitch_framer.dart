import 'dart:typed_data';

import 'yin_pitch_detector.dart';

/// Turns 16-bit little-endian mono PCM, chunk by chunk, into pitches: keeps the last
/// [YinPitchDetector.windowSize] samples in a ring and asks the detector every [hopSize] new samples.
///
/// When a chunk completes several hops only the newest one is analyzed: an older pitch would show late.
final class PcmPitchFramer {
  static const double _fullScale = 32768;
  static const int _bitsPerByte = 8;
  static const int _sampleBits = 16;

  final YinPitchDetector _detector;

  /// New samples between two pitches.
  final int hopSize;

  final Float64List _ring;
  final Float64List _window;
  int _written = 0;
  int _sinceLast = 0;
  int? _lowByte;

  /// Creates a framer that feeds [detector].
  PcmPitchFramer(YinPitchDetector detector, {required this.hopSize})
    : _detector = detector,
      _ring = Float64List(detector.windowSize),
      _window = Float64List(detector.windowSize);

  /// The pitch of the newest window that [chunk] completed (`null` inside for a piece without a clear pitch),
  /// or nothing when the chunk completed no hop.
  List<double?> add(Uint8List chunk) {
    bool isDue = false;
    for (final int byte in chunk) {
      final int? low = _lowByte;
      if (low == null) {
        _lowByte = byte;
        continue;
      }
      _lowByte = null;
      _ring[_written++ % _ring.length] = (byte << _bitsPerByte | low).toSigned(_sampleBits) / _fullScale;
      if (_written >= _ring.length && ++_sinceLast >= hopSize) {
        _sinceLast = 0;
        isDue = true;
      }
    }
    return isDue ? <double?>[_detector.detect(_unrolled())] : const <double?>[];
  }

  /// The ring from its oldest sample to its newest.
  Float64List _unrolled() {
    final int oldest = _written % _ring.length;
    _window.setRange(0, _ring.length - oldest, _ring, oldest);
    _window.setRange(_ring.length - oldest, _ring.length, _ring);
    return _window;
  }
}
