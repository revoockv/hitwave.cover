import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:hitwave.cover/features/vocal_enhance/data/data_sources/package_vocal_enhance_data_source.dart';
import 'package:hitwave.cover/features/vocal_enhance/data/data_sources/vocal_enhance_data_source.dart';
import 'package:hitwave.cover/features/vocal_enhance/data/models/enhance_progress_model.dart';
import 'package:hitwave.cover/features/vocal_enhance/data/models/enhance_report_model.dart';
import 'package:hitwave.cover/features/vocal_enhance/data/models/recording_analysis_model.dart';

/// 16-bit mono WAV: [leadIn] seconds of room noise, then a sung-like tone.
Uint8List vocalTakeWav({double seconds = 6, double leadIn = 1.5, int rate = 48000}) {
  final Random random = Random(3);
  final int frames = (seconds * rate).round();
  final ByteData data = ByteData(44 + frames * 2);
  void ascii(int offset, String text) => text.codeUnits.asMap().forEach((int i, int c) => data.setUint8(offset + i, c));
  ascii(0, 'RIFF');
  data.setUint32(4, 36 + frames * 2, Endian.little);
  ascii(8, 'WAVEfmt ');
  data.setUint32(16, 16, Endian.little);
  data.setUint16(20, 1, Endian.little);
  data.setUint16(22, 1, Endian.little);
  data.setUint32(24, rate, Endian.little);
  data.setUint32(28, rate * 2, Endian.little);
  data.setUint16(32, 2, Endian.little);
  data.setUint16(34, 16, Endian.little);
  ascii(36, 'data');
  data.setUint32(40, frames * 2, Endian.little);
  for (int i = 0; i < frames; i++) {
    final double t = i / rate;
    double voice = 0;
    if (t >= leadIn) {
      for (int k = 1; k < 10; k++) {
        voice += 0.3 / k * sin(2 * pi * 220 * k * t);
      }
    }
    final double noise = (random.nextDouble() - 0.5) * 0.01;
    data.setInt16(44 + i * 2, ((voice * 0.3 + noise) * 32767).round().clamp(-32768, 32767), Endian.little);
  }
  return data.buffer.asUint8List();
}

void main() {
  late Directory folder;
  late PackageVocalEnhanceDataSource engine;

  setUp(() {
    folder = Directory.systemTemp.createTempSync('vocal_enhance');
    engine = PackageVocalEnhanceDataSource();
  });

  tearDown(() {
    engine.dispose();
    folder.deleteSync(recursive: true);
  });

  test('analyzes and enhances a take in a background isolate', () async {
    final File raw = File('${folder.path}/take.wav')..writeAsBytesSync(vocalTakeWav());
    final String output = '${folder.path}/take_studio.wav';
    final List<EnhanceProgressModel> steps = <EnhanceProgressModel>[];

    final RecordingAnalysisModel analysis = await engine.analyze(raw.path);
    final EnhanceReportModel report = await engine.enhance(
      inputPath: raw.path,
      outputPath: output,
      preset: 'studio',
      settings: const <String, double>{'noise_profile_seconds': 1.4, 'trim_silence': 1},
      onProgress: steps.add,
    );

    expect(analysis.durationSeconds, closeTo(6, 0.01));
    expect(analysis.sampleRate, 48000);
    expect(steps.map((EnhanceProgressModel s) => s.step).toSet(), hasLength(steps.first.steps));
    for (int i = 1; i < steps.length; i++) {
      expect(steps[i].fraction, greaterThanOrEqualTo(steps[i - 1].fraction));
    }
    expect(File(output).existsSync(), isTrue);
    expect(File('$output.part').existsSync(), isFalse);
    expect(report.settings['noise_reduction_db'], 22); // the studio preset
    expect(report.settings['noise_profile_seconds'], 1.4);
    expect(report.after.integratedLufs, closeTo(-14, 0.5));
    expect(report.after.truePeakDb, lessThanOrEqualTo(-0.9));
    expect(report.keptFromSeconds, greaterThan(1));
    expect(report.keptToSeconds, closeTo(6, 0.01));
  });

  for (final String preset in <String>['natural', 'studio', 'loudness', 'classic']) {
    test('a mono take comes out as pseudo-stereo with the $preset preset', () async {
      final File raw = File('${folder.path}/take.wav')..writeAsBytesSync(vocalTakeWav(seconds: 3, leadIn: 1));
      final String output = '${folder.path}/take_$preset.wav';

      final EnhanceReportModel report = await engine.enhance(
        inputPath: raw.path,
        outputPath: output,
        preset: preset,
        settings: const <String, double>{'widen_mono': 0},
        onProgress: (_) {},
      );

      final ByteData header = ByteData.sublistView(File(output).readAsBytesSync(), 0, 44);
      expect(header.getUint16(22, Endian.little), 2);
      expect(report.settings['widen_mono'], 1);
    });
  }

  test('a missing file fails with an engine exception', () async {
    await expectLater(engine.analyze('${folder.path}/missing.wav'), throwsA(isA<VocalEnhanceEngineException>()));
  });

  test('digital silence has no loudness', () async {
    final Uint8List bytes = vocalTakeWav(seconds: 1, leadIn: 1)..fillRange(44, 44 + 48000 * 2, 0);
    final File silent = File('${folder.path}/silent.wav')..writeAsBytesSync(bytes);
    final RecordingAnalysisModel analysis = await engine.analyze(silent.path);
    expect(analysis.integratedLufs, isNull);
  });

  test('dispose stops a running enhancement', () async {
    final File raw = File('${folder.path}/take.wav')..writeAsBytesSync(vocalTakeWav());
    final Future<EnhanceReportModel> running = engine.enhance(
      inputPath: raw.path,
      outputPath: '${folder.path}/out.wav',
      preset: 'natural',
      settings: const <String, double>{},
      onProgress: (_) {},
    );
    await Future<void>.delayed(const Duration(milliseconds: 50));
    engine.dispose();
    await expectLater(running, throwsA(isA<VocalEnhanceEngineException>()));
  });
}
