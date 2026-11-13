import '../../../../core/domain/entities/result.dart';

import '../repositories/song_repository.dart';
import '../entities/song_failure.dart';

/// Use case for deleting a song.
///
/// Wraps the repository [deleteSong] method as a single-responsibility use case.
/// Returns [Result<void, SongFailure>] indicating success or failure.
final class DeleteSongUseCase {
  final SongRepository _repository;

  /// Creates a new [DeleteSongUseCase] use case.
  DeleteSongUseCase(this._repository);

  /// Deletes a song identified by [songId] and all its associated covers.
  ///
  /// Returns [SuccessResult] when the song is deleted, or [FailureResult]
  /// with an error message when the operation fails.
  Future<Result<void, SongFailure>> call({required String songId}) async {
    return _repository.deleteSong(songId: songId);
  }
}
