import '../../../../core/domain/entities/result.dart';

import '../repositories/song_repository.dart';

/// Use case for updating an existing cover.
///
/// Wraps the repository [updateCover] method as a single-responsibility use case.
/// Returns [Result<void>] indicating success or failure.
final class UpdateCoverUseCase {
  final SongRepository _repository;

  /// Creates a new [UpdateCoverUseCase] use case.
  UpdateCoverUseCase(this._repository);

  /// Updates a cover identified by [coverId] on the song [songId] with the
  /// given [audioBytes] and optional [notes].
  ///
  /// Returns [SuccessResult] when the cover is updated, or [FailureResult]
  /// with an error message when the operation fails.
  Future<Result<void>> call({
    required String songId,
    required String coverId,
    required List<int> audioBytes,
    String? notes,
  }) async {
    return _repository.updateCover(
      songId: songId,
      coverId: coverId,
      audioBytes: audioBytes,
      notes: notes,
    );
  }
}
