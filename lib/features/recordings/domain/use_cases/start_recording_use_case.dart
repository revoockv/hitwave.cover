import '../../../../core/domain/entities/result.dart';
import '../repositories/recordings_repository.dart';

/// Use case that starts recording a take of a song from the microphone.
final class StartRecordingUseCase {
  final RecordingsRepository _repository;

  /// Creates a [StartRecordingUseCase].
  StartRecordingUseCase(this._repository);

  /// Starts recording a take of [songId].
  Future<Result<void>> call(String songId) async {
    return _repository.startRecording(songId);
  }
}
