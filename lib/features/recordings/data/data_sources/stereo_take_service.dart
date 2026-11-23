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
  static const double _powerBase = 10;
  static const double _powerDbStep = 10;
  static const int _channelCount = 2;
  static const int _max16 = 32767;
  static const int _min16 = -32768;
  static const int _headerSize = 44;
  static const int _bytesPerSample = 2;
  static const int _bits = 16;
  static const String _partSuffix = '.part';

  // RIFF/WAVE header: chunk ids, their offsets and the PCM format fields.
  static const String _riffId = 'RIFF';
  static const String _waveId = 'WAVE';
  static const String _formatId = 'fmt ';
  static const String _dataId = 'data';
  static const int _riffAt = 0;
  static const int _riffSizeAt = 4;
  static const int _riffSizeExcluded = 8;
  static const int _waveAt = 8;
  static const int _formatAt = 12;
  static const int _formatSizeAt = 16;
  static const int _formatSize = 16;
  static const int _audioFormatAt = 20;
  static const int _pcmFormat = 1;
  static const int _channelsAt = 22;
  static const int _monoChannels = 1;
  static const int _sampleRateAt = 24;
  static const int _byteRateAt = 28;
  static const int _blockAlignAt = 32;
  static const int _bitsAt = 34;
  static const int _dataAt = 36;
  static const int _dataSizeAt = 40;

  /// Rewrites the WAV file at [path] as 16-bit mono when its two channels carry the same
  /// signal; returns whether it did. Mono and real stereo files stay as they are.
  Future<bool> collapseFakeStereo(String path) => Isolate.run(() => _collapse(path));

  static Future<bool> _collapse(String path) async {
    final File file = File(path);
    final WavPcmModel wav = WavPcmModel.fromBytes(await file.readAsBytes());
    if (wav.channels.length != _channelCount) return false;
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
    if (side > mid * math.pow(_powerBase, _sameChannelsDb / _powerDbStep)) return false;
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

    id(_riffAt, _riffId);
    data.setUint32(_riffSizeAt, _headerSize - _riffSizeExcluded + dataSize, Endian.little);
    id(_waveAt, _waveId);
    id(_formatAt, _formatId);
    data.setUint32(_formatSizeAt, _formatSize, Endian.little);
    data.setUint16(_audioFormatAt, _pcmFormat, Endian.little);
    data.setUint16(_channelsAt, _monoChannels, Endian.little);
    data.setUint32(_sampleRateAt, sampleRate, Endian.little);
    data.setUint32(_byteRateAt, sampleRate * _bytesPerSample, Endian.little);
    data.setUint16(_blockAlignAt, _bytesPerSample, Endian.little);
    data.setUint16(_bitsAt, _bits, Endian.little);
    id(_dataAt, _dataId);
    data.setUint32(_dataSizeAt, dataSize, Endian.little);
    for (int i = 0; i < left.length; i++) {
      final int value = ((left[i] + right[i]) / _channelCount * _scale16).round().clamp(_min16, _max16);
      data.setInt16(_headerSize + i * _bytesPerSample, value, Endian.little);
    }
    return data.buffer.asUint8List();
  }
}
