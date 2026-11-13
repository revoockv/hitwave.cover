import '../../../../core/domain/entities/result.dart';
import '../entities/song_failure.dart';
import '../repositories/song_repository.dart';

/// Use case that deletes every song of the library with its covers.
final class DeleteAllSongsUseCase {
  final SongRepository _repository;

  /// Creates a [DeleteAllSongsUseCase].
  DeleteAllSongsUseCase(this._repository);

  /// Runs it; the first failure stops it.
  Future<Result<void, SongFailure>> call() async {
    return _repository.deleteAllSongs();
  }
}
