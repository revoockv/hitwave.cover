import '../../../../core/domain/entities/result.dart';
import '../repositories/sync_repository.dart';
import '../entities/sync_failure.dart';

/// Use case that goes on with a synchronisation after the user chose the changes to make.
final class ApplySyncChangesUseCase {
  final SyncRepository _repository;

  /// Creates an [ApplySyncChangesUseCase].
  ApplySyncChangesUseCase(this._repository);

  /// Makes the changes whose ids are in [chosen]; the others are not made this time.
  Future<Result<void, SyncFailure>> call(Set<String> chosen) async {
    return _repository.applyChanges(chosen);
  }
}
