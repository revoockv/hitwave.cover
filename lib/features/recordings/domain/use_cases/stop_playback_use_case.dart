import '../../../../core/domain/entities/result.dart';
import '../repositories/playback_repository.dart';
import '../entities/recordings_failure.dart';

/// Use case that stops the playing recording.
final class StopPlaybackUseCase {
  final PlaybackRepository _repository;

  /// Creates a [StopPlaybackUseCase].
  StopPlaybackUseCase(this._repository);

  /// Stops playing.
  Future<Result<void, RecordingsFailure>> call() async {
    return _repository.stop();
  }
}
