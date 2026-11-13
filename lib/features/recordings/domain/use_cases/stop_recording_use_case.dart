import '../../../../core/domain/entities/result.dart';
import '../entities/recording.dart';
import '../repositories/recordings_repository.dart';
import '../entities/recordings_failure.dart';

/// Use case that stops the take, keeps it and enhances it automatically.
final class StopRecordingUseCase {
  final RecordingsRepository _repository;

  /// Creates a [StopRecordingUseCase].
  StopRecordingUseCase(this._repository);

  /// Stops the take; [trimSilence] cuts the silence around the singing in the enhanced file.
  Future<Result<Recording, RecordingsFailure>> call({required bool trimSilence}) async {
    return _repository.stopRecording(trimSilence: trimSilence);
  }
}
