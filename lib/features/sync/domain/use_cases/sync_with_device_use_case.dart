import '../../../../core/domain/entities/result.dart';
import '../repositories/sync_repository.dart';

/// Use case that synchronises with the device showing a code.
final class SyncWithDeviceUseCase {
  static const String _emptyCodeError = 'Введіть або відскануйте код';

  final SyncRepository _repository;

  /// Creates a [SyncWithDeviceUseCase].
  SyncWithDeviceUseCase(this._repository);

  /// Synchronises with the device that shows [code].
  Future<Result<void>> call(String code) async {
    if (code.trim().isEmpty) return const Result.failure(_emptyCodeError);
    return _repository.syncWith(code.trim());
  }
}
