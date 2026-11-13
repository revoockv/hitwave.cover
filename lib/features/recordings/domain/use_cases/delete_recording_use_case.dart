import '../../../../core/domain/entities/result.dart';
import '../repositories/recordings_repository.dart';
import '../entities/recordings_failure.dart';

/// Use case that deletes a recording and its files.
final class DeleteRecordingUseCase {
  final RecordingsRepository _repository;

  /// Creates a [DeleteRecordingUseCase].
  DeleteRecordingUseCase(this._repository);

  /// Deletes the recording [recordingId].
  Future<Result<void, RecordingsFailure>> call(String recordingId) async {
    return _repository.deleteRecording(recordingId);
  }
}
