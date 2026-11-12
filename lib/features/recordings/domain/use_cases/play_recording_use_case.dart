import '../../../../core/domain/entities/result.dart';
import '../entities/recording.dart';
import '../entities/recording_version.dart';
import '../repositories/playback_repository.dart';

/// Use case that plays the original or the enhanced file of a recording.
final class PlayRecordingUseCase {
  final PlaybackRepository _repository;

  /// Creates a [PlayRecordingUseCase].
  PlayRecordingUseCase(this._repository);

  /// Plays [version] of [recording] from the start.
  Future<Result<void>> call({required Recording recording, required RecordingVersion version}) async {
    return _repository.play(recording: recording, version: version);
  }
}
