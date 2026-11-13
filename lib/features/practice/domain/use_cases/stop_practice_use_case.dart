import '../../../../core/domain/entities/result.dart';
import '../repositories/practice_repository.dart';

/// Use case that ends the practice session being measured.
final class StopPracticeUseCase {
  final PracticeRepository _repository;

  /// Creates a [StopPracticeUseCase].
  StopPracticeUseCase(this._repository);

  /// Ends the session and keeps it when it counts.
  Future<Result<void>> call() async {
    return _repository.stopPractice();
  }
}
