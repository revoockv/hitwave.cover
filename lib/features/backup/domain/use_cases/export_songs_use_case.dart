import '../../../../core/domain/result.dart';

import '../repositories/backup_repository.dart';

/// Use case that exports all songs to a JSON file.
///
/// Wraps the repository [exportSongs] method as a single-responsibility
/// use case. Returns [Result<void>] indicating success or failure.
final class ExportSongsUseCase {
  final BackupRepository _repository;

  /// Creates a new [ExportSongsUseCase] use case.
  ExportSongsUseCase(this._repository);

  /// Exports all songs to a JSON file at the given [filePath].
  ///
  /// Returns [SuccessResult] on success, or [FailureResult] with an error
  /// message when the export fails.
  Future<Result<void>> call(String filePath) async {
    return _repository.exportSongs(filePath);
  }
}
