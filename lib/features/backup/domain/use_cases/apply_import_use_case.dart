import '../../../../core/domain/entities/result.dart';
import '../entities/backup_failure.dart';
import '../entities/import_choice.dart';
import '../entities/import_summary.dart';
import '../repositories/backup_repository.dart';

/// Imports the opened backup.
final class ApplyImportUseCase {
  final BackupRepository _repository;

  /// Creates an [ApplyImportUseCase].
  ApplyImportUseCase(this._repository);

  /// Imports the opened backup; [choices] says what to do with each conflict (by its index).
  Future<Result<ImportSummary, BackupFailure>> call(Map<int, ImportChoice> choices) => _repository.applyImport(choices);
}
