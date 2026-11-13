import '../../../../core/domain/entities/result.dart';
import '../repositories/sync_repository.dart';

/// Use case that stops waiting for another device or closes the result.
final class StopSyncUseCase {
  final SyncRepository _repository;

  /// Creates a [StopSyncUseCase].
  StopSyncUseCase(this._repository);

  /// Goes back to idle.
  Future<Result<void>> call() async {
    return _repository.stopSync();
  }
}
