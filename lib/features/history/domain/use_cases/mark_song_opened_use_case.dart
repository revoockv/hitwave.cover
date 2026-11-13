import '../../../../core/domain/entities/result.dart';
import '../repositories/history_repository.dart';

/// Use case that remembers a song was opened.
final class MarkSongOpenedUseCase {
  final HistoryRepository _repository;

  /// Creates a [MarkSongOpenedUseCase].
  MarkSongOpenedUseCase(this._repository);

  /// Remembers that [songId] was opened now.
  Future<Result<void>> call(String songId) async {
    return _repository.markSongOpened(songId);
  }
}
