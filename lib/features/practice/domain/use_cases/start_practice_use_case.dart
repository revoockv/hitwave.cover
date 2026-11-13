import '../../../../core/domain/entities/result.dart';
import '../repositories/practice_repository.dart';
import '../entities/practice_failure.dart';

/// Use case that starts measuring the practice of a song.
final class StartPracticeUseCase {
  final PracticeRepository _repository;

  /// Creates a [StartPracticeUseCase].
  StartPracticeUseCase(this._repository);

  /// Starts measuring the practice of [songId].
  Future<Result<void, PracticeFailure>> call(String songId) async {
    return _repository.startPractice(songId);
  }
}
