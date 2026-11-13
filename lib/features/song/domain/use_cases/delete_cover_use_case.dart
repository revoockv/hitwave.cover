import '../../../../core/domain/entities/result.dart';

import '../repositories/song_repository.dart';
import '../entities/song_failure.dart';

/// Use case for deleting a cover from a song.
///
/// Wraps the repository [deleteCover] method as a single-responsibility use case.
/// Returns [Result<void, SongFailure>] indicating success or failure.
final class DeleteCoverUseCase {
  final SongRepository _repository;

  /// Creates a new [DeleteCoverUseCase] use case.
  DeleteCoverUseCase(this._repository);

  /// Deletes a cover identified by [coverId] from the song [songId].
  ///
  /// Returns [SuccessResult] when the cover is deleted, or [FailureResult]
  /// with an error message when the operation fails.
  Future<Result<void, SongFailure>> call({required String songId, required String coverId}) async {
    return _repository.deleteCover(songId: songId, coverId: coverId);
  }
}
