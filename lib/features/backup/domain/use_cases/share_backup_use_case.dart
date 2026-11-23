import '../../../../core/domain/entities/result.dart';
import '../entities/backup_failure.dart';
import '../repositories/backup_repository.dart';

/// Use case that makes a backup and opens the share sheet with it (Google Drive and other apps).
final class ShareBackupUseCase {
  final BackupRepository _repository;

  /// Creates a [ShareBackupUseCase].
  ShareBackupUseCase(this._repository);

  /// Shares the songs, with their takes when [includeRecordings].
  Future<Result<void, BackupFailure>> call({required bool includeRecordings}) async {
    return _repository.shareBackup(includeRecordings: includeRecordings);
  }
}
