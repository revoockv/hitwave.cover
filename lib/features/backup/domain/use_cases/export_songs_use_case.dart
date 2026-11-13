import '../../../../core/domain/entities/result.dart';

import '../repositories/backup_repository.dart';
import '../entities/backup_failure.dart';

/// Use case that exports all songs to a user-selected JSON file.
///
/// Wraps the repository [exportSongs] method as a single-responsibility
/// use case. Returns [Result<void, BackupFailure>] indicating success or failure.
/// The directory picker is called internally by the repository.
final class ExportSongsUseCase {
  final BackupRepository _repository;

  /// Creates a new [ExportSongsUseCase] use case.
  ExportSongsUseCase(this._repository);

  /// Exports all songs to a JSON file in a user-selected directory.
  ///
  /// Prompts the user to select an export directory via file picker,
  /// then writes all songs to a `backup.json` file within that directory.
  /// [pickerTitle] is the title of the folder picker.
  /// Returns [SuccessResult] on success, or [FailureResult] with an error
  /// message when the export fails.
  ///
  /// [includeRecordings] adds the recordings of the songs (the file becomes a ZIP).
  Future<Result<void, BackupFailure>> call({required bool includeRecordings, required String pickerTitle}) async {
    return _repository.exportSongs(includeRecordings: includeRecordings, pickerTitle: pickerTitle);
  }
}
