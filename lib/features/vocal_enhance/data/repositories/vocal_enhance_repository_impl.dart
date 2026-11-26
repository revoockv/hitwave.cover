import 'package:flutter/foundation.dart';
import 'package:logger/logger.dart';

import '../../../../core/domain/entities/disposable_resource.dart';
import '../../../../core/domain/entities/result.dart';
import '../../domain/entities/enhance_preset.dart';
import '../../domain/entities/enhance_progress.dart';
import '../../domain/entities/enhance_report.dart';
import '../../domain/entities/recording_analysis.dart';
import '../../domain/repositories/vocal_enhance_repository.dart';
import '../data_sources/vocal_enhance_data_source.dart';
import '../models/enhance_progress_model.dart';
import '../models/enhance_report_model.dart';
import '../models/recording_analysis_model.dart';
import '../../domain/entities/vocal_enhance_failure.dart';
import '../../domain/entities/enhance_setting.dart';

/// [VocalEnhanceRepository] on top of the audio engine; converts engine errors to failures.
final class VocalEnhanceRepositoryImpl implements VocalEnhanceRepository, DisposableResource {
  static const String _noiseProfileSetting = 'noise_profile_seconds';
  static const String _trimSilenceSetting = 'trim_silence';
  static const double _on = 1;
  static const String _analyzeSuccessLog = 'AnalyzeRecording: success — ';
  static const String _analyzeFailureLog = 'AnalyzeRecording: failure — ';
  static const String _enhanceStartLog = 'EnhanceRecording: starting — ';
  static const String _enhanceSuccessLog = 'EnhanceRecording: success — ';
  static const String _enhanceFailureLog = 'EnhanceRecording: failure — ';
  static const String _lufsLog = ' LUFS';
  static const String _arrowLog = ' → ';
  static const String _secondsLog = 's, ';
  static const String _colonLog = ': ';
  static const String _commaLog = ', ';

  final VocalEnhanceDataSource _dataSource;
  final Logger _logger;
  final ValueNotifier<EnhanceProgress?> _progress = ValueNotifier<EnhanceProgress?>(null);

  /// Creates a [VocalEnhanceRepositoryImpl].
  VocalEnhanceRepositoryImpl({required this._dataSource, required this._logger});

  /// Releases the progress state.
  @override
  void dispose() {
    _progress.dispose();
  }

  @override
  ValueListenable<EnhanceProgress?> watchProgress() => _progress;

  @override
  Future<Result<RecordingAnalysis, VocalEnhanceFailure>> analyzeRecording(String path) async {
    try {
      final RecordingAnalysisModel model = await _dataSource.analyze(path);
      _logger.i('$_analyzeSuccessLog$path$_colonLog${model.integratedLufs}$_lufsLog');
      return Result.success(model.toEntity());
    } on Exception catch (e) {
      _logger.e('$_analyzeFailureLog$path$_colonLog$e');
      return Result.failure(_failureOf(e, VocalEnhanceFailure.analyze));
    }
  }

  @override
  Future<Result<EnhanceReport, VocalEnhanceFailure>> enhanceRecording({
    required String inputPath,
    required String outputPath,
    required EnhancePreset preset,
    required double? roomToneSeconds,
    required bool trimSilence,
    required List<EnhanceSetting> settings,
  }) async {
    _logger.i('$_enhanceStartLog$inputPath$_arrowLog$outputPath');
    try {
      final EnhanceReportModel model = await _dataSource.enhance(
        inputPath: inputPath,
        outputPath: outputPath,
        preset: preset.name,
        settings: <String, double>{
          for (final EnhanceSetting setting in settings) setting.name: setting.value,
          _noiseProfileSetting: ?roomToneSeconds,
          if (trimSilence) _trimSilenceSetting: _on,
        },
        onProgress: _onProgress,
      );
      _logger.i(
        '$_enhanceSuccessLog${model.before.integratedLufs}$_arrowLog${model.after.integratedLufs}$_lufsLog'
        '$_commaLog${model.secondsSpent}$_secondsLog${model.outputPath}',
      );
      return Result.success(model.toEntity());
    } on Exception catch (e) {
      _logger.e('$_enhanceFailureLog$inputPath$_colonLog$e');
      return Result.failure(_failureOf(e, VocalEnhanceFailure.enhance));
    } finally {
      _progress.value = null;
    }
  }

  /// [unavailable] when the engine does not run here, [otherwise] for anything else.
  static VocalEnhanceFailure _failureOf(Exception error, VocalEnhanceFailure otherwise) =>
      error is VocalEnhanceEngineException && error.isUnavailable ? VocalEnhanceFailure.unavailable : otherwise;

  void _onProgress(EnhanceProgressModel progress) {
    _progress.value = progress.toEntity();
  }
}
