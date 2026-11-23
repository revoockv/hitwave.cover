import '../../../../core/domain/entities/result.dart';

import '../repositories/song_repository.dart';
import '../entities/song_failure.dart';

/// Use case for saving the lyrics of a song edited on the lyrics page.
///
/// Wraps the repository [SongRepository.updateSongLyrics] method.
final class UpdateSongLyricsUseCase {
  final SongRepository _repository;

  /// Creates a new [UpdateSongLyricsUseCase] use case.
  UpdateSongLyricsUseCase(this._repository);

  /// Saves [lyrics] for the song identified by [songId].
  Future<Result<void, SongFailure>> call({required String songId, required String lyrics}) async {
    return _repository.updateSongLyrics(songId: songId, lyrics: lyrics);
  }
}
