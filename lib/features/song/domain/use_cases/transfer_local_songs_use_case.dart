import '../../../../core/domain/entities/result.dart';

import '../repositories/song_repository.dart';
import '../entities/song_failure.dart';

/// Use case for moving the songs on the device into the signed-in account.
final class TransferLocalSongsUseCase {
  final SongRepository _repository;

  /// Creates a new [TransferLocalSongsUseCase] use case.
  TransferLocalSongsUseCase(this._repository);

  /// Moves the songs; the ones that failed stay on the device.
  Future<Result<void, SongFailure>> call() async {
    return _repository.transferLocalSongs();
  }
}
