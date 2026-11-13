import 'dart:typed_data';

/// The samples of a WAV file as floating point numbers in [-1, 1], one list per channel.
///
/// Reads uncompressed PCM of 16, 24 or 32 bits and 32-bit float, the formats the recorder and
/// the audio engine write.
final class WavPcmModel {
  static const String _riff = 'RIFF';
  static const String _wave = 'WAVE';
  static const String _formatChunk = 'fmt ';
  static const String _dataChunk = 'data';
  static const int _pcm = 1;
  static const int _float = 3;
  static const int _extensible = 0xFFFE;
  static const int _headerSize = 12;
  static const int _chunkHeaderSize = 8;
  static const int _idSize = 4;
  static const int _bitsPerByte = 8;
  static const int _bits16 = 16;
  static const int _bits24 = 24;
  static const int _bits32 = 32;
  static const double _scale16 = 32768;
  static const double _scale24 = 8388608;
  static const double _scale32 = 2147483648;
  static const int _sign24 = 0x800000;
  static const int _wrap24 = 0x1000000;
  static const int _subFormatOffset = 24;
  static const int _bitsOffset = 14;
  static const String _notWavError = 'Це не WAV-файл';
  static const String _formatError = 'Непідтримуваний формат WAV';

  /// Samples per second.
  final int sampleRate;

  /// The samples of every channel.
  final List<Float64List> channels;

  /// Creates a [WavPcmModel].
  const WavPcmModel({required this.sampleRate, required this.channels});

  /// Reads the WAV file in [bytes]; throws a [FormatException] for anything else.
  factory WavPcmModel.fromBytes(Uint8List bytes) {
    final ByteData data = ByteData.sublistView(bytes);
    if (bytes.length < _headerSize || _id(bytes, 0) != _riff || _id(bytes, _idSize * 2) != _wave) {
      throw const FormatException(_notWavError);
    }
    int format = 0;
    int channelCount = 0;
    int sampleRate = 0;
    int bits = 0;
    int position = _headerSize;
    while (position + _chunkHeaderSize <= bytes.length) {
      final String id = _id(bytes, position);
      final int size = data.getUint32(position + _idSize, Endian.little);
      final int body = position + _chunkHeaderSize;
      if (id == _formatChunk) {
        format = data.getUint16(body, Endian.little);
        channelCount = data.getUint16(body + 2, Endian.little);
        sampleRate = data.getUint32(body + _idSize, Endian.little);
        bits = data.getUint16(body + _bitsOffset, Endian.little);
        if (format == _extensible && size >= _subFormatOffset + 2) {
          format = data.getUint16(body + _subFormatOffset, Endian.little);
        }
      } else if (id == _dataChunk) {
        return WavPcmModel._read(bytes, data, body, size, format, channelCount, sampleRate, bits);
      }
      position = body + size + (size & 1);
    }
    throw const FormatException(_notWavError);
  }

  static WavPcmModel _read(
    Uint8List bytes,
    ByteData data,
    int body,
    int size,
    int format,
    int channelCount,
    int sampleRate,
    int bits,
  ) {
    final bool isFloat = format == _float && bits == _bits32;
    final bool isPcm = format == _pcm && (bits == _bits16 || bits == _bits24 || bits == _bits32);
    if ((!isFloat && !isPcm) || channelCount < 1 || sampleRate <= 0) throw const FormatException(_formatError);
    final int width = bits ~/ _bitsPerByte;
    final int available = (body + size <= bytes.length ? size : bytes.length - body) ~/ (width * channelCount);
    final List<Float64List> channels = <Float64List>[
      for (int channel = 0; channel < channelCount; channel++) Float64List(available),
    ];
    for (int frame = 0; frame < available; frame++) {
      for (int channel = 0; channel < channelCount; channel++) {
        final int at = body + (frame * channelCount + channel) * width;
        channels[channel][frame] = switch ((isFloat, bits)) {
          (true, _) => data.getFloat32(at, Endian.little),
          (false, _bits16) => data.getInt16(at, Endian.little) / _scale16,
          (false, _bits24) => _int24(bytes, at) / _scale24,
          _ => data.getInt32(at, Endian.little) / _scale32,
        };
      }
    }
    return WavPcmModel(sampleRate: sampleRate, channels: channels);
  }

  static int _int24(Uint8List bytes, int at) {
    final int value = bytes[at] | bytes[at + 1] << _bitsPerByte | bytes[at + 2] << (_bitsPerByte * 2);
    return value & _sign24 != 0 ? value - _wrap24 : value;
  }

  static String _id(Uint8List bytes, int at) => String.fromCharCodes(bytes, at, at + _idSize);
}
