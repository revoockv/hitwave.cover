import '../../../../core/domain/entities/result.dart';
import '../entities/practice_failure.dart';
import '../repositories/practice_repository.dart';

/// Deletes one practice session.
final class DeletePracticeSessionUseCase {
  final PracticeRepository _repository;

  /// Creates a [DeletePracticeSessionUseCase].
  DeletePracticeSessionUseCase(this._repository);

  /// Deletes the session [sessionId]; a synchronisation does not bring it back.
  Future<Result<void, PracticeFailure>> call(String sessionId) => _repository.deleteSession(sessionId);
}
