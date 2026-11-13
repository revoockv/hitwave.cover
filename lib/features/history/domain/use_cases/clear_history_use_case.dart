import '../../../../core/domain/entities/result.dart';
import '../entities/history_failure.dart';
import '../repositories/history_repository.dart';

/// Use case that forgets which songs were opened and which covers played.
final class ClearHistoryUseCase {
  final HistoryRepository _repository;

  /// Creates a [ClearHistoryUseCase].
  ClearHistoryUseCase(this._repository);

  /// Runs it; the first failure stops it.
  Future<Result<void, HistoryFailure>> call() async {
    return _repository.clearHistory();
  }
}
