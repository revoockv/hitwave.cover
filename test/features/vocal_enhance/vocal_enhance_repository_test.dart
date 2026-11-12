import 'package:flutter_test/flutter_test.dart';
import 'package:hitwave.cover/core/domain/entities/result.dart';
import 'package:hitwave.cover/features/vocal_enhance/data/data_sources/vocal_enhance_data_source.dart';
import 'package:hitwave.cover/features/vocal_enhance/data/models/enhance_progress_model.dart';
import 'package:hitwave.cover/features/vocal_enhance/data/models/enhance_report_model.dart';
import 'package:hitwave.cover/features/vocal_enhance/data/models/recording_analysis_model.dart';
import 'package:hitwave.cover/features/vocal_enhance/data/repositories/vocal_enhance_repository_impl.dart';
import 'package:hitwave.cover/features/vocal_enhance/domain/entities/enhance_preset.dart';
import 'package:hitwave.cover/features/vocal_enhance/domain/entities/enhance_progress.dart';
import 'package:hitwave.cover/features/vocal_enhance/domain/entities/enhance_report.dart';
import 'package:hitwave.cover/features/vocal_enhance/domain/use_cases/enhance_recording_use_case.dart';
import 'package:logger/logger.dart';

const RecordingAnalysisModel analysis = RecordingAnalysisModel(
  durationSeconds: 3,
  sampleRate: 48000,
  channels: 1,
  integratedLufs: -14,
  truePeakDb: -1,
  clippedPercent: 0,
  noiseFloorDb: -60,
  signalToNoiseDb: 40,
  isClipped: false,
  isTooQuiet: false,
  isNoisy: false,
);

/// An engine that reports two steps and succeeds, or fails with [error].
final class FakeEngine implements VocalEnhanceDataSource {
  final String? error;
  final List<String> presets = <String>[];
  final List<Map<String, double>> settings = <Map<String, double>>[];
  final List<EnhanceProgress?> progressSeen = <EnhanceProgress?>[];
  VocalEnhanceRepositoryImpl? repository;

  FakeEngine({this.error});

  @override
  Future<RecordingAnalysisModel> analyze(String inputPath) async {
    final String? failure = error;
    if (failure != null) {
      throw VocalEnhanceEngineException(failure);
    }
    return analysis;
  }

  @override
  Future<EnhanceReportModel> enhance({
    required String inputPath,
    required String outputPath,
    required String preset,
    required Map<String, double> settings,
    required void Function(EnhanceProgressModel progress) onProgress,
  }) async {
    presets.add(preset);
    this.settings.add(settings);
    for (int step = 1; step <= 2; step++) {
      onProgress(EnhanceProgressModel(step: step, steps: 2, label: 'step', fraction: (step - 1) / 2));
      progressSeen.add(repository?.watchProgress().value);
    }
    final String? failure = error;
    if (failure != null) {
      throw VocalEnhanceEngineException(failure);
    }
    return EnhanceReportModel(
      inputPath: inputPath,
      outputPath: outputPath,
      settings: settings,
      before: analysis,
      after: analysis,
      secondsSpent: 0.5,
    );
  }
}

void main() {
  late FakeEngine engine;
  late VocalEnhanceRepositoryImpl repository;
  late EnhanceRecordingUseCase enhanceRecordingUseCase;

  void build({String? error}) {
    engine = FakeEngine(error: error);
    repository = VocalEnhanceRepositoryImpl(
      dataSource: engine,
      logger: Logger(level: Level.off),
    );
    engine.repository = repository;
    enhanceRecordingUseCase = EnhanceRecordingUseCase(repository);
  }

  test('enhances with the preset name and the room tone, and shows the progress meanwhile', () async {
    build();

    final Result<EnhanceReport> result = await enhanceRecordingUseCase(
      inputPath: '/raw.wav',
      outputPath: '/clean.wav',
      preset: EnhancePreset.studio,
      roomToneSeconds: 1.5,
      trimSilence: true,
      settings: const <String, double>{'air_db': 3},
    );

    expect(result.isSuccess, isTrue);
    expect(engine.presets, <String>['studio']);
    expect(engine.settings.single, <String, double>{'air_db': 3, 'noise_profile_seconds': 1.5, 'trim_silence': 1});
    expect(engine.progressSeen.map((EnhanceProgress? p) => p?.step), <int>[1, 2]);
    expect(repository.watchProgress().value, isNull);
  });

  test('leaves the noise profile to the engine without a room tone', () async {
    build();

    await enhanceRecordingUseCase(inputPath: '/raw.wav', outputPath: '/clean.wav');

    expect(engine.presets, <String>['natural']);
    expect(engine.settings.single, isEmpty);
  });

  test('an engine error becomes a failure and the progress is cleared', () async {
    build(error: 'no such file: /raw.wav');

    final Result<EnhanceReport> result = await enhanceRecordingUseCase(inputPath: '/raw.wav', outputPath: '/clean.wav');

    expect(
      result,
      isA<FailureResult<EnhanceReport>>().having(
        (FailureResult<EnhanceReport> f) => f.error,
        'error',
        contains('no such file'),
      ),
    );
    expect(repository.watchProgress().value, isNull);
    expect((await repository.analyzeRecording('/raw.wav')).isFailure, isTrue);
  });

  test('the use case rejects bad paths and a negative room tone without the engine', () async {
    build();

    for (final Future<Result<EnhanceReport>> request in <Future<Result<EnhanceReport>>>[
      enhanceRecordingUseCase(inputPath: '/a.wav', outputPath: '/a.wav'),
      enhanceRecordingUseCase(inputPath: '/a.wav', outputPath: '/a.mp3'),
      enhanceRecordingUseCase(inputPath: '/a.wav', outputPath: '/b.wav', roomToneSeconds: -1),
    ]) {
      expect((await request).isFailure, isTrue);
    }
    expect(engine.presets, isEmpty);
  });
}
