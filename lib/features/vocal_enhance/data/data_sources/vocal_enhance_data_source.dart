import '../models/enhance_progress_model.dart';
import '../models/enhance_report_model.dart';
import '../models/recording_analysis_model.dart';

/// Thrown when the audio engine cannot run a request; [message] is the engine's explanation.
final class VocalEnhanceEngineException implements Exception {
  /// What went wrong, for the log.
  final String message;

  /// Whether the engine does not run on this platform at all.
  final bool isUnavailable;

  /// Creates a [VocalEnhanceEngineException].
  const VocalEnhanceEngineException(this.message, {this.isUnavailable = false});

  @override
  String toString() => message;
}

/// The audio engine (the revoockv_audio_enhance package) seen as requests and answers.
///
/// May throw [VocalEnhanceEngineException]; the repository converts it to a failure.
abstract interface class VocalEnhanceDataSource {
  /// Measures the WAV file at [inputPath].
  Future<RecordingAnalysisModel> analyze(String inputPath);

  /// Enhances [inputPath] into [outputPath] with the engine's [preset] name and [settings].
  ///
  /// [onProgress] is called when every step starts.
  Future<EnhanceReportModel> enhance({
    required String inputPath,
    required String outputPath,
    required String preset,
    required Map<String, double> settings,
    required void Function(EnhanceProgressModel progress) onProgress,
  });
}
