import '../../../../core/domain/entities/result.dart';

import '../repositories/song_repository.dart';
import '../entities/song_failure.dart';

/// Use case for saving the auto-scroll speed of a song's lyrics.
///
/// Wraps the repository [SongRepository.updateSongScrollSpeed] method.
final class UpdateSongScrollSpeedUseCase {
  final SongRepository _repository;

  /// Creates a new [UpdateSongScrollSpeedUseCase] use case.
  UpdateSongScrollSpeedUseCase(this._repository);

  /// Saves [speed] (0.0–1.0) for the song identified by [songId].
  Future<Result<void, SongFailure>> call({required String songId, required double speed}) async {
    return _repository.updateSongScrollSpeed(songId: songId, speed: speed);
  }
}
