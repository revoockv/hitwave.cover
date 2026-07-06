import '../../../../core/domain/result.dart';

import '../repositories/song_repository.dart';

/// Use case for updating an existing song.
///
/// Wraps the repository [updateSong] method as a single-responsibility use case.
/// Returns [Result<void>] indicating success or failure.
final class UpdateSongUseCase {
  final SongRepository _repository;

  /// Creates a new [UpdateSongUseCase] use case.
  UpdateSongUseCase(this._repository);

  /// Updates a song identified by [songId] with the given [author], [name],
  /// optional [album], and [lyrics].
  ///
  /// Returns [SuccessResult] when the song is updated, or [FailureResult]
  /// with an error message when the operation fails.
  Future<Result<void>> call({
    required String songId,
    required String author,
    required String name,
    String? album,
    required String lyrics,
  }) async {
    return _repository.updateSong(
      songId: songId,
      author: author,
      name: name,
      album: album,
      lyrics: lyrics,
    );
  }
}
