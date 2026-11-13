import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:hitwave.cover/features/recordings/data/data_sources/mp3_encoder_service.dart';
import 'package:hitwave.cover/features/recordings/data/models/wav_pcm_model.dart';

/// A mono WAV of a 440 Hz tone at 48 kHz with [bits] per sample.
Uint8List toneWav({required int bits, double seconds = 1}) {
  const int rate = 48000;
  final int frames = (rate * seconds).round();
  final int width = bits ~/ 8;
  final ByteData data = ByteData(44 + frames * width);
  void id(int at, String text) => text.codeUnits.asMap().forEach((int i, int c) => data.setUint8(at + i, c));
  id(0, 'RIFF');
  data.setUint32(4, 36 + frames * width, Endian.little);
  id(8, 'WAVE');
  id(12, 'fmt ');
  data.setUint32(16, 16, Endian.little);
  data.setUint16(20, 1, Endian.little);
  data.setUint16(22, 1, Endian.little);
  data.setUint32(24, rate, Endian.little);
  data.setUint32(28, rate * width, Endian.little);
  data.setUint16(32, width, Endian.little);
  data.setUint16(34, bits, Endian.little);
  id(36, 'data');
  data.setUint32(40, frames * width, Endian.little);
  for (int i = 0; i < frames; i++) {
    final double v = 0.5 * sin(2 * pi * 440 * i / rate);
    if (bits == 16) {
      data.setInt16(44 + i * 2, (v * 32767).round(), Endian.little);
    } else {
      final int x = (v * 8388607).round() & 0xFFFFFF;
      data.setUint8(44 + i * 3, x & 0xFF);
      data.setUint8(45 + i * 3, (x >> 8) & 0xFF);
      data.setUint8(46 + i * 3, (x >> 16) & 0xFF);
    }
  }
  return data.buffer.asUint8List();
}

void main() {
  test('16- and 24-bit WAV read as the same samples', () {
    final WavPcmModel pcm16 = WavPcmModel.fromBytes(toneWav(bits: 16));
    final WavPcmModel pcm24 = WavPcmModel.fromBytes(toneWav(bits: 24));
    expect(pcm16.sampleRate, 48000);
    expect(pcm24.channels.single.length, 48000);
    expect(pcm24.channels.single[12], closeTo(pcm16.channels.single[12], 1e-4));
    expect(() => WavPcmModel.fromBytes(Uint8List.fromList(<int>[1, 2, 3])), throwsFormatException);
  });

  test('a take becomes an MP3 of the same length', () async {
    final Directory folder = await Directory.systemTemp.createTemp('hitwave_mp3_test');
    addTearDown(() => folder.delete(recursive: true));
    final File wav = File('${folder.path}/take.wav')..writeAsBytesSync(toneWav(bits: 24, seconds: 2));
    final String mp3 = '${folder.path}/take.mp3';

    await Mp3EncoderService().encode(wavPath: wav.path, mp3Path: mp3);

    final Uint8List bytes = File(mp3).readAsBytesSync();
    expect(bytes[0], 0xFF); // frame sync
    expect(bytes[1] & 0xE0, 0xE0);
    // 192 kbit/s × 2 s ≈ 48 KB.
    expect(bytes.length, inInclusiveRange(40000, 56000));
  });
}
