import '../models/enhance_progress_model.dart';
import '../models/enhance_report_model.dart';
import '../models/recording_analysis_model.dart';
import 'vocal_enhance_data_source.dart';

/// The web has no files to read the takes from, so the engine is not available there.
VocalEnhanceDataSource createVocalEnhanceDataSource() => const _UnsupportedVocalEnhanceDataSource();

final class _UnsupportedVocalEnhanceDataSource implements VocalEnhanceDataSource {
  static const String _unavailableError = 'Vocal enhancement is not available on this platform';

  const _UnsupportedVocalEnhanceDataSource();

  @override
  Future<RecordingAnalysisModel> analyze(String inputPath) =>
      Future<RecordingAnalysisModel>.error(const VocalEnhanceEngineException(_unavailableError, isUnavailable: true));

  @override
  Future<EnhanceReportModel> enhance({
    required String inputPath,
    required String outputPath,
    required String preset,
    required Map<String, double> settings,
    required void Function(EnhanceProgressModel progress) onProgress,
  }) => Future<EnhanceReportModel>.error(const VocalEnhanceEngineException(_unavailableError, isUnavailable: true));
}
