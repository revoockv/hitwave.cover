import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:hitwave.cover/features/recordings/data/data_sources/stereo_take_service.dart';
import 'package:hitwave.cover/features/recordings/data/models/wav_pcm_model.dart';

/// A 16-bit WAV with one list of integer samples per channel.
Uint8List wav16(List<List<int>> channels, {int rate = 48000}) {
  final int frames = channels.first.length;
  final int count = channels.length;
  final ByteData data = ByteData(44 + frames * count * 2);
  void id(int at, String text) => text.codeUnits.asMap().forEach((int i, int c) => data.setUint8(at + i, c));
  id(0, 'RIFF');
  data.setUint32(4, 36 + frames * count * 2, Endian.little);
  id(8, 'WAVEfmt ');
  data.setUint32(16, 16, Endian.little);
  data.setUint16(20, 1, Endian.little);
  data.setUint16(22, count, Endian.little);
  data.setUint32(24, rate, Endian.little);
  data.setUint32(28, rate * count * 2, Endian.little);
  data.setUint16(32, count * 2, Endian.little);
  data.setUint16(34, 16, Endian.little);
  id(36, 'data');
  data.setUint32(40, frames * count * 2, Endian.little);
  for (int i = 0; i < frames; i++) {
    for (int c = 0; c < count; c++) {
      data.setInt16(44 + (i * count + c) * 2, channels[c][i], Endian.little);
    }
  }
  return data.buffer.asUint8List();
}

void main() {
  late Directory folder;
  final StereoTakeService service = StereoTakeService();
  final Random random = Random(5);
  final List<int> voice = <int>[
    for (int i = 0; i < 48000; i++) (8000 * sin(i / 9) + random.nextInt(200) - 100).round(),
  ];

  setUp(() => folder = Directory.systemTemp.createTempSync('stereo_take'));
  tearDown(() => folder.deleteSync(recursive: true));

  test('two equal channels become mono with the same samples', () async {
    final File file = File('${folder.path}/take.wav')..writeAsBytesSync(wav16(<List<int>>[voice, voice]));
    expect(await service.collapseFakeStereo(file.path), isTrue);
    final WavPcmModel mono = WavPcmModel.fromBytes(file.readAsBytesSync());
    expect(mono.channels, hasLength(1));
    expect(mono.sampleRate, 48000);
    expect(<int>[for (final double v in mono.channels.first) (v * 32768).round()], voice);
    expect(File('${file.path}.part').existsSync(), isFalse);
  });

  test('real stereo stays stereo', () async {
    final List<int> other = <int>[for (int i = 0; i < 48000; i++) (6000 * sin(i / 7)).round()];
    final File file = File('${folder.path}/take.wav')..writeAsBytesSync(wav16(<List<int>>[voice, other]));
    final Uint8List before = file.readAsBytesSync();
    expect(await service.collapseFakeStereo(file.path), isFalse);
    expect(file.readAsBytesSync(), before);
  });

  test('a mono take is left alone', () async {
    final File file = File('${folder.path}/take.wav')..writeAsBytesSync(wav16(<List<int>>[voice]));
    expect(await service.collapseFakeStereo(file.path), isFalse);
  });
}
