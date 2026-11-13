import '../../../../core/domain/entities/result.dart';

import '../repositories/song_repository.dart';
import '../entities/song_failure.dart';

/// Use case for keeping the songs on the device instead of moving them into the account.
final class KeepLocalSongsUseCase {
  final SongRepository _repository;

  /// Creates a new [KeepLocalSongsUseCase] use case.
  KeepLocalSongsUseCase(this._repository);

  /// Keeps the songs on the device and stops asking until they change.
  Future<Result<void, SongFailure>> call() async {
    return _repository.keepLocalSongs();
  }
}
