import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:hitwave.cover/features/vocal_enhance/data/data_sources/python_vocal_enhance_data_source.dart';
import 'package:hitwave.cover/features/vocal_enhance/data/data_sources/serious_python_engine_channel.dart';
import 'package:hitwave.cover/features/vocal_enhance/data/models/enhance_progress_model.dart';
import 'package:hitwave.cover/features/vocal_enhance/data/models/enhance_report_model.dart';
import 'package:hitwave.cover/features/vocal_enhance/data/models/recording_analysis_model.dart';
import 'package:integration_test/integration_test.dart';
import 'package:path_provider/path_provider.dart';

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

/// Runs the embedded Python engine of the built app. Build and run it with the Python packaged:
///   tool/flutter_python.sh macos test integration_test/vocal_enhance_test.dart -d macos
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('the embedded Python engine analyzes and enhances a take on the device', (WidgetTester tester) async {
    final Directory folder = await Directory(
      '${(await getTemporaryDirectory()).path}/vocal_enhance',
    ).create(recursive: true);
    final File raw = File('${folder.path}/vocal_enhance_take.wav')..writeAsBytesSync(vocalTakeWav());
    final String output = '${folder.path}/vocal_enhance_take_studio.wav';
    final PythonVocalEnhanceDataSource engine = PythonVocalEnhanceDataSource(SeriousPythonEngineChannel());
    final List<EnhanceProgressModel> steps = <EnhanceProgressModel>[];
    final Stopwatch clock = Stopwatch()..start();

    final RecordingAnalysisModel analysis = await engine.analyze(raw.path);
    final Duration started = clock.elapsed;
    final EnhanceReportModel report = await engine.enhance(
      inputPath: raw.path,
      outputPath: output,
      preset: 'studio',
      settings: const <String, double>{'noise_profile_seconds': 1.4},
      onProgress: steps.add,
    );

    // ignore: avoid_print
    print(
      'vocal_enhance on device: start+analyze ${started.inMilliseconds} ms, enhance ${report.secondsSpent} s, '
      '${report.before.integratedLufs} → ${report.after.integratedLufs} LUFS, '
      'SNR ${report.before.signalToNoiseDb} → ${report.after.signalToNoiseDb} dB',
    );
    expect(analysis.durationSeconds, closeTo(6, 0.01));
    expect(steps, hasLength(10));
    expect(File(output).existsSync(), isTrue);
    expect(report.after.integratedLufs, closeTo(-14, 0.5));
    expect(report.after.truePeakDb, lessThanOrEqualTo(-0.7));
  }, timeout: const Timeout(Duration(minutes: 3)));
}
