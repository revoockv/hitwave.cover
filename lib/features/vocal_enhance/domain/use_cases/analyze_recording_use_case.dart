import '../../../../core/domain/entities/result.dart';
import '../entities/recording_analysis.dart';
import '../repositories/vocal_enhance_repository.dart';

/// Use case that measures a take, so the user learns whether it is clipped, too quiet or noisy.
final class AnalyzeRecordingUseCase {
  final VocalEnhanceRepository _repository;

  /// Creates an [AnalyzeRecordingUseCase].
  AnalyzeRecordingUseCase(this._repository);

  /// Returns the levels of the WAV file at [path].
  Future<Result<RecordingAnalysis>> call(String path) async {
    return _repository.analyzeRecording(path);
  }
}
