import '../../../../core/domain/entities/result.dart';
import '../entities/recordings_failure.dart';
import '../repositories/recordings_repository.dart';

/// Use case that deletes every take of every song.
final class DeleteAllRecordingsUseCase {
  final RecordingsRepository _repository;

  /// Creates a [DeleteAllRecordingsUseCase].
  DeleteAllRecordingsUseCase(this._repository);

  /// Runs it; the first failure stops it.
  Future<Result<void, RecordingsFailure>> call() async {
    return _repository.deleteAllRecordings();
  }
}
