import '../../../../core/domain/entities/result.dart';
import '../repositories/sync_repository.dart';
import '../entities/sync_failure.dart';

/// Use case that synchronises with the device showing a code.
final class SyncWithDeviceUseCase {
  final SyncRepository _repository;

  /// Creates a [SyncWithDeviceUseCase].
  SyncWithDeviceUseCase(this._repository);

  /// Synchronises with the device that shows [code].
  Future<Result<void, SyncFailure>> call(String code) async {
    if (code.trim().isEmpty) return const Result.failure(SyncFailure.emptyCode);
    return _repository.syncWith(code.trim());
  }
}
