import '../../../../core/domain/entities/result.dart';
import '../entities/backup_failure.dart';
import '../entities/import_plan.dart';
import '../repositories/backup_repository.dart';

/// Lets the user pick a backup file and reads it, without importing anything yet.
final class OpenImportUseCase {
  final BackupRepository _repository;

  /// Creates an [OpenImportUseCase].
  OpenImportUseCase(this._repository);

  /// The plan of the picked backup, or `null` when the user cancelled the picker.
  /// [includeRecordings] also imports the takes of a ZIP backup.
  Future<Result<ImportPlan?, BackupFailure>> call({required bool includeRecordings}) =>
      _repository.openImport(includeRecordings: includeRecordings);
}
