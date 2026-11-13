import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:hitwave.cover/features/vocal_enhance/data/data_sources/python_engine_channel.dart';
import 'package:hitwave.cover/features/vocal_enhance/data/data_sources/python_vocal_enhance_data_source.dart';
import 'package:hitwave.cover/features/vocal_enhance/data/data_sources/vocal_enhance_data_source.dart';
import 'package:hitwave.cover/features/vocal_enhance/data/models/enhance_progress_model.dart';
import 'package:hitwave.cover/features/vocal_enhance/data/models/enhance_report_model.dart';
import 'package:hitwave.cover/features/vocal_enhance/data/models/recording_analysis_model.dart';

/// A Python engine scripted in Dart: answers every request through [answer].
final class ScriptedChannel implements PythonEngineChannel {
  final StreamController<Uint8List> _messages = StreamController<Uint8List>.broadcast();
  final List<Map<String, dynamic>> requests = <Map<String, dynamic>>[];
  final List<Map<String, dynamic>> Function(Map<String, dynamic> request) answer;
  final Map<String, dynamic> startEvent;
  int refusedSends;

  ScriptedChannel(
    this.answer, {
    this.startEvent = const <String, dynamic>{'event': 'ready', 'protocol': 1},
    this.refusedSends = 0,
  });

  void emit(Map<String, dynamic> event) => _messages.add(utf8.encode(jsonEncode(event)));

  @override
  Stream<Uint8List> get messages => _messages.stream;

  @override
  Future<void> start() async => scheduleMicrotask(() => emit(startEvent));

  @override
  bool send(Uint8List bytes) {
    if (refusedSends > 0) {
      refusedSends--;
      return false;
    }
    final Map<String, dynamic> request = jsonDecode(utf8.decode(bytes)) as Map<String, dynamic>;
    requests.add(request);
    scheduleMicrotask(() => answer(request).forEach(emit));
    return true;
  }

  @override
  void close() => unawaited(_messages.close());
}

/// The real engine: `vocal-enhance enhance worker` of the skill, one JSON message per line.
final class ProcessChannel implements PythonEngineChannel {
  final String project;
  final StreamController<Uint8List> _messages = StreamController<Uint8List>.broadcast();
  Process? _process;

  ProcessChannel(this.project);

  @override
  Stream<Uint8List> get messages => _messages.stream;

  @override
  Future<void> start() async {
    final Process process = await Process.start('uv', <String>[
      'run',
      '--project',
      project,
      'vocal-enhance',
      'enhance',
      'worker',
    ]);
    _process = process;
    process.stdout
        .transform(utf8.decoder)
        .transform(const LineSplitter())
        .listen((String line) => _messages.add(utf8.encode(line)));
    process.stderr.drain<void>();
  }

  @override
  bool send(Uint8List bytes) {
    final Process? process = _process;
    if (process == null) {
      return false;
    }
    process.stdin.add(<int>[...bytes, 10]);
    return true;
  }

  @override
  void close() {
    _process?.kill();
    unawaited(_messages.close());
  }
}

const Map<String, dynamic> analysisJson = <String, dynamic>{
  'duration_s': 2.0,
  'sample_rate': 48000,
  'channels': 1,
  'integrated_lufs': -20.5,
  'true_peak_db': -3.0,
  'clipped_percent': 0.0,
  'noise_floor_db': null,
  'signal_to_noise_db': null,
  'is_clipped': false,
  'is_too_quiet': false,
  'is_noisy': false,
};

/// 16-bit mono WAV: [seconds] of room noise, then a sung-like tone.
Uint8List vocalTakeWav({double seconds = 4, double leadIn = 1, int rate = 48000}) {
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
  group('protocol (scripted engine)', () {
    test('starts once, waits for ready and returns the analysis', () async {
      final ScriptedChannel channel = ScriptedChannel(
        (Map<String, dynamic> request) => <Map<String, dynamic>>[
          <String, dynamic>{'event': 'analysis', 'id': request['id'], 'analysis': analysisJson},
        ],
        refusedSends: 3,
      );
      final PythonVocalEnhanceDataSource dataSource = PythonVocalEnhanceDataSource(channel);

      final RecordingAnalysisModel first = await dataSource.analyze('/a.wav');
      final RecordingAnalysisModel second = await dataSource.analyze('/b.wav');

      expect(first.integratedLufs, -20.5);
      expect(first.noiseFloorDb, isNull);
      expect(second.sampleRate, 48000);
      expect(channel.requests.map((Map<String, dynamic> r) => r['input']), <String>['/a.wav', '/b.wav']);
      expect(channel.requests.map((Map<String, dynamic> r) => r['id']).toSet(), hasLength(2));
      dataSource.dispose();
    });

    test('streams progress and returns the report of an enhancement', () async {
      final ScriptedChannel channel = ScriptedChannel(
        (Map<String, dynamic> request) => <Map<String, dynamic>>[
          for (int step = 1; step <= 3; step++)
            <String, dynamic>{
              'event': 'progress',
              'id': request['id'],
              'step': step,
              'steps': 3,
              'label': 'Step $step',
              'fraction': (step - 1) / 3,
            },
          <String, dynamic>{
            'event': 'done',
            'id': request['id'],
            'report': <String, dynamic>{
              'input': request['input'],
              'output': request['output'],
              'settings': <String, dynamic>{'target_lufs': -14, ...request['settings'] as Map<String, dynamic>},
              'before': analysisJson,
              'after': analysisJson,
              'seconds': 1.25,
            },
          },
        ],
      );
      final PythonVocalEnhanceDataSource dataSource = PythonVocalEnhanceDataSource(channel);
      final List<EnhanceProgressModel> steps = <EnhanceProgressModel>[];

      final EnhanceReportModel report = await dataSource.enhance(
        inputPath: '/raw.wav',
        outputPath: '/clean.wav',
        preset: 'studio',
        settings: const <String, double>{'noise_profile_seconds': 1.5},
        onProgress: steps.add,
      );

      expect(channel.requests.single['preset'], 'studio');
      expect(steps.map((EnhanceProgressModel s) => s.step), <int>[1, 2, 3]);
      expect(report.outputPath, '/clean.wav');
      expect(report.settings, <String, double>{'target_lufs': -14, 'noise_profile_seconds': 1.5});
      expect(report.secondsSpent, 1.25);
      dataSource.dispose();
    });

    test('turns an engine error into an exception with its message', () async {
      final PythonVocalEnhanceDataSource dataSource = PythonVocalEnhanceDataSource(
        ScriptedChannel(
          (Map<String, dynamic> request) => <Map<String, dynamic>>[
            <String, dynamic>{'event': 'error', 'id': request['id'], 'message': 'no such file: /a.wav'},
          ],
        ),
      );

      await expectLater(
        dataSource.analyze('/a.wav'),
        throwsA(
          isA<VocalEnhanceEngineException>().having(
            (VocalEnhanceEngineException e) => e.message,
            'message',
            'no such file: /a.wav',
          ),
        ),
      );
    });

    test('reports a Python startup failure', () async {
      final PythonVocalEnhanceDataSource dataSource = PythonVocalEnhanceDataSource(
        ScriptedChannel(
          (Map<String, dynamic> request) => <Map<String, dynamic>>[],
          startEvent: const <String, dynamic>{'event': 'startup_error', 'message': 'No module named numpy'},
        ),
      );

      await expectLater(
        dataSource.analyze('/a.wav'),
        throwsA(
          isA<VocalEnhanceEngineException>().having(
            (VocalEnhanceEngineException e) => e.message,
            'message',
            contains('numpy'),
          ),
        ),
      );
    });

    test('rejects an engine with another protocol version', () async {
      final PythonVocalEnhanceDataSource dataSource = PythonVocalEnhanceDataSource(
        ScriptedChannel(
          (Map<String, dynamic> request) => <Map<String, dynamic>>[],
          startEvent: const <String, dynamic>{'event': 'ready', 'protocol': 2},
        ),
      );

      await expectLater(dataSource.analyze('/a.wav'), throwsA(isA<VocalEnhanceEngineException>()));
    });

    test('says the feature is unavailable without embedded Python (web)', () async {
      await expectLater(
        PythonVocalEnhanceDataSource(null).analyze('/a.wav'),
        throwsA(isA<VocalEnhanceEngineException>()),
      );
    });
  });

  final String skill = '${Platform.environment['HOME']}/.agents/skills/revoockv-vocal-enhance';
  final bool hasEngine =
      File('$skill/pyproject.toml').existsSync() && Process.runSync('which', <String>['uv']).exitCode == 0;

  group('protocol (real engine)', () {
    late Directory folder;

    setUp(() => folder = Directory.systemTemp.createTempSync('vocal_enhance_test'));
    tearDown(() => folder.deleteSync(recursive: true));

    test('the Dart side and the Python worker agree on every message', () async {
      final File raw = File('${folder.path}/take.wav')..writeAsBytesSync(vocalTakeWav());
      final String output = '${folder.path}/take_enhanced.wav';
      final PythonVocalEnhanceDataSource dataSource = PythonVocalEnhanceDataSource(ProcessChannel(skill));
      final List<EnhanceProgressModel> steps = <EnhanceProgressModel>[];

      final RecordingAnalysisModel analysis = await dataSource.analyze(raw.path);
      final EnhanceReportModel report = await dataSource.enhance(
        inputPath: raw.path,
        outputPath: output,
        preset: 'natural',
        settings: const <String, double>{'noise_profile_seconds': 0.9},
        onProgress: steps.add,
      );
      await expectLater(dataSource.analyze('${folder.path}/missing.wav'), throwsA(isA<VocalEnhanceEngineException>()));
      dataSource.dispose();

      expect(analysis.durationSeconds, closeTo(4, 0.01));
      expect(steps.map((EnhanceProgressModel s) => s.step), List<int>.generate(10, (int i) => i + 1));
      expect(File(output).existsSync(), isTrue);
      expect(report.settings['noise_profile_seconds'], 0.9);
      expect(report.after.integratedLufs, closeTo(-14, 0.5));
      expect(report.after.truePeakDb, lessThanOrEqualTo(-0.7));
      expect(report.after.signalToNoiseDb!, greaterThan(report.before.signalToNoiseDb! + 3));
    }, timeout: const Timeout(Duration(minutes: 2)));
  }, skip: hasEngine ? false : 'the revoockv-vocal-enhance skill or uv is not installed');
}
