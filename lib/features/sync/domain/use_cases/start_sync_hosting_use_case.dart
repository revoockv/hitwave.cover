import '../../../../core/domain/entities/result.dart';
import '../repositories/sync_repository.dart';
import '../entities/sync_failure.dart';

/// Use case that makes this device wait for another one to synchronise with.
final class StartSyncHostingUseCase {
  final SyncRepository _repository;

  /// Creates a [StartSyncHostingUseCase].
  StartSyncHostingUseCase(this._repository);

  /// Starts waiting; the code to show comes with the state.
  Future<Result<void, SyncFailure>> call() async {
    return _repository.startHosting();
  }
}
