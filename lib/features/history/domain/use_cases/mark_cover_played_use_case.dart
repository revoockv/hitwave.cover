import '../../../../core/domain/entities/result.dart';
import '../repositories/history_repository.dart';
import '../entities/history_failure.dart';

/// Use case that remembers a cover was played.
final class MarkCoverPlayedUseCase {
  final HistoryRepository _repository;

  /// Creates a [MarkCoverPlayedUseCase].
  MarkCoverPlayedUseCase(this._repository);

  /// Remembers that the cover [recordingId] was played now.
  Future<Result<void, HistoryFailure>> call(String recordingId) async {
    return _repository.markCoverPlayed(recordingId);
  }
}
