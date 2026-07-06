import '../../../../core/domain/result.dart';

import '../repositories/song_repository.dart';

/// Use case for adding a cover to a song.
///
/// Wraps the repository [addCover] method as a single-responsibility use case.
/// Returns [Result<void>] indicating success or failure.
final class AddCoverUseCase {
  final SongRepository _repository;

  /// Creates a new [AddCoverUseCase] use case.
  AddCoverUseCase(this._repository);

  /// Adds a new cover to the song identified by [songId] with the given
  /// [audioBytes] and optional [notes].
  ///
  /// Returns [SuccessResult] when the cover is created, or [FailureResult]
  /// with an error message when the operation fails.
  Future<Result<void>> call({
    required String songId,
    required List<int> audioBytes,
    String? notes,
  }) async {
    return _repository.addCover(
      songId: songId,
      audioBytes: audioBytes,
      notes: notes,
    );
  }
}
