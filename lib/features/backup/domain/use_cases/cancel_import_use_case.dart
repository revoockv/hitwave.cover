import '../repositories/backup_repository.dart';

/// Drops the opened backup without importing anything.
final class CancelImportUseCase {
  final BackupRepository _repository;

  /// Creates a [CancelImportUseCase].
  CancelImportUseCase(this._repository);

  /// Drops the opened backup.
  Future<void> call() => _repository.cancelImport();
}
