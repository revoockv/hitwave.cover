import '../../../../core/domain/entities/result.dart';
import '../repositories/recordings_repository.dart';
import '../entities/recordings_failure.dart';

/// Use case that starts recording a take of a song from the microphone.
final class StartRecordingUseCase {
  final RecordingsRepository _repository;

  /// Creates a [StartRecordingUseCase].
  StartRecordingUseCase(this._repository);

  /// Starts recording a take of [songId] from [microphoneId] (the system input when `null`).
  Future<Result<void, RecordingsFailure>> call(String songId, {String? microphoneId}) async {
    return _repository.startRecording(songId, microphoneId: microphoneId);
  }
}
