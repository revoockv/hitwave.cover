import '../../../../core/domain/entities/result.dart';
import '../entities/backup_failure.dart';
import '../entities/import_decision.dart';
import '../entities/import_summary.dart';
import '../repositories/backup_repository.dart';

/// Imports the opened backup.
final class ApplyImportUseCase {
  final BackupRepository _repository;

  /// Creates an [ApplyImportUseCase].
  ApplyImportUseCase(this._repository);

  /// Imports the opened backup; [decisions] say what to do with the conflicts, one without a decision is skipped.
  Future<Result<ImportSummary, BackupFailure>> call(List<ImportDecision> decisions) =>
      _repository.applyImport(decisions);
}
