import '../../../../core/domain/entities/result.dart';

import '../repositories/song_repository.dart';
import '../entities/song_failure.dart';

/// Use case for saving the space above a song's lyrics before they scroll.
///
/// Wraps the repository [SongRepository.updateSongLeadIn] method.
final class UpdateSongLeadInUseCase {
  final SongRepository _repository;

  /// Creates a new [UpdateSongLeadInUseCase] use case.
  UpdateSongLeadInUseCase(this._repository);

  /// Saves [leadIn] (a part of the screen height) for the song identified by [songId].
  Future<Result<void, SongFailure>> call({required String songId, required double leadIn}) async {
    return _repository.updateSongLeadIn(songId: songId, leadIn: leadIn);
  }
}
