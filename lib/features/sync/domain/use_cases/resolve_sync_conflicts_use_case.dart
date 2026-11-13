import '../../../../core/domain/entities/result.dart';
import '../entities/sync_conflict.dart';
import '../repositories/sync_repository.dart';
import '../entities/sync_failure.dart';

/// Use case that goes on with a synchronisation after the user decided about its conflicts.
final class ResolveSyncConflictsUseCase {
  final SyncRepository _repository;

  /// Creates a [ResolveSyncConflictsUseCase].
  ResolveSyncConflictsUseCase(this._repository);

  /// Does for every conflict (by id) what [choices] says.
  Future<Result<void, SyncFailure>> call(Map<String, SyncChoice> choices) async {
    return _repository.resolveConflicts(choices);
  }
}
