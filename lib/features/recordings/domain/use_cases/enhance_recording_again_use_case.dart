import '../../../../core/domain/entities/result.dart';
import '../repositories/recordings_repository.dart';

/// Use case that enhances a recording again after its enhancement failed.
final class EnhanceRecordingAgainUseCase {
  final RecordingsRepository _repository;

  /// Creates a [EnhanceRecordingAgainUseCase].
  EnhanceRecordingAgainUseCase(this._repository);

  /// Enhances the raw take of [recordingId] again.
  Future<Result<void>> call({required String recordingId, required bool trimSilence}) async {
    return _repository.enhanceAgain(recordingId: recordingId, trimSilence: trimSilence);
  }
}
