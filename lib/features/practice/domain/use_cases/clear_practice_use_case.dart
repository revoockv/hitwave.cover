import '../../../../core/domain/entities/result.dart';
import '../entities/practice_failure.dart';
import '../repositories/practice_repository.dart';

/// Use case that forgets every practice session.
final class ClearPracticeUseCase {
  final PracticeRepository _repository;

  /// Creates a [ClearPracticeUseCase].
  ClearPracticeUseCase(this._repository);

  /// Runs it; the first failure stops it.
  Future<Result<void, PracticeFailure>> call() async {
    return _repository.clearSessions();
  }
}
