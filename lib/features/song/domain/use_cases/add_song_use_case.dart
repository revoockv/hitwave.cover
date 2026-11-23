import '../../../../core/domain/entities/result.dart';

import '../repositories/song_repository.dart';
import '../entities/song_failure.dart';

/// Use case for adding a new song.
///
/// Wraps the repository [addSong] method as a single-responsibility use case.
/// Returns [Result<void, SongFailure>] indicating success or failure.
final class AddSongUseCase {
  final SongRepository _repository;

  /// Creates a new [AddSongUseCase] use case.
  AddSongUseCase(this._repository);

  /// Adds a new song with the given [author], [name], optional [album], and [lyrics].
  ///
  /// Returns [SuccessResult] when the song is created, or [FailureResult]
  /// with an error message when the operation fails.
  Future<Result<void, SongFailure>> call({
    required String author,
    required String name,
    String? album,
    required String lyrics,
  }) async {
    return _repository.addSong(author: author, name: name, album: album, lyrics: lyrics);
  }
}
