import 'dart:io';
import 'dart:isolate';
import 'dart:math' as math;
import 'dart:typed_data';

import '../models/wav_pcm_model.dart';

/// Keeps a stereo take only when it really is stereo.
///
/// The recorder asks for two channels, so devices with a stereo microphone record stereo. On a
/// mono microphone the platform fills both channels with the same signal; such a take is
/// rewritten as mono, which halves the file and changes nothing audible. Runs in a background
/// isolate.
class StereoTakeService {
  /// The channels count as one when their difference is this far below their sum.
  static const double _sameChannelsDb = -50;
  static const double _scale16 = 32768;
  static const int _max16 = 32767;
  static const int _min16 = -32768;
  static const int _headerSize = 44;
  static const int _bytesPerSample = 2;
  static const int _bits = 16;
  static const String _partSuffix = '.part';

  /// Rewrites the WAV file at [path] as 16-bit mono when its two channels carry the same
  /// signal; returns whether it did. Mono and real stereo files stay as they are.
  Future<bool> collapseFakeStereo(String path) => Isolate.run(() => _collapse(path));

  static Future<bool> _collapse(String path) async {
    final File file = File(path);
    final WavPcmModel wav = WavPcmModel.fromBytes(await file.readAsBytes());
    if (wav.channels.length != 2) return false;
    final Float64List left = wav.channels[0];
    final Float64List right = wav.channels[1];
    double mid = 0;
    double side = 0;
    for (int i = 0; i < left.length; i++) {
      final double sum = left[i] + right[i];
      final double difference = left[i] - right[i];
      mid += sum * sum;
      side += difference * difference;
    }
    if (side > mid * math.pow(10, _sameChannelsDb / 10)) return false;
    final File part = File('$path$_partSuffix');
    await part.writeAsBytes(_mono16(left, right, wav.sampleRate), flush: true);
    await part.rename(path);
    return true;
  }

  /// A 16-bit mono WAV of the average of [left] and [right] (exactly [left] when they are equal).
  static Uint8List _mono16(Float64List left, Float64List right, int sampleRate) {
    final int dataSize = left.length * _bytesPerSample;
    final ByteData data = ByteData(_headerSize + dataSize);
    void id(int at, String text) {
      for (int i = 0; i < text.length; i++) {
        data.setUint8(at + i, text.codeUnitAt(i));
      }
    }

    id(0, 'RIFF');
    data.setUint32(4, _headerSize - 8 + dataSize, Endian.little);
    id(8, 'WAVE');
    id(12, 'fmt ');
    data.setUint32(16, 16, Endian.little);
    data.setUint16(20, 1, Endian.little);
    data.setUint16(22, 1, Endian.little);
    data.setUint32(24, sampleRate, Endian.little);
    data.setUint32(28, sampleRate * _bytesPerSample, Endian.little);
    data.setUint16(32, _bytesPerSample, Endian.little);
    data.setUint16(34, _bits, Endian.little);
    id(36, 'data');
    data.setUint32(40, dataSize, Endian.little);
    for (int i = 0; i < left.length; i++) {
      final int value = ((left[i] + right[i]) / 2 * _scale16).round().clamp(_min16, _max16);
      data.setInt16(_headerSize + i * _bytesPerSample, value, Endian.little);
    }
    return data.buffer.asUint8List();
  }
}
