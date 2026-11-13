import '../../../../core/domain/entities/result.dart';
import '../repositories/playback_repository.dart';
import '../entities/recordings_failure.dart';

/// Use case that pauses the playing recording or continues it.
final class TogglePlaybackPauseUseCase {
  final PlaybackRepository _repository;

  /// Creates a [TogglePlaybackPauseUseCase].
  TogglePlaybackPauseUseCase(this._repository);

  /// Pauses or continues.
  Future<Result<void, RecordingsFailure>> call() async {
    return _repository.togglePause();
  }
}
