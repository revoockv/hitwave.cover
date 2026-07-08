import '../../../../core/domain/result.dart';

import '../repositories/backup_repository.dart';

/// Use case that imports songs from a JSON file.
///
/// Wraps the repository [importSongs] method as a single-responsibility
/// use case. Returns [Result<void>] indicating success or failure.
final class ImportSongsUseCase {
  final BackupRepository _repository;

  /// Creates a new [ImportSongsUseCase] use case.
  ImportSongsUseCase(this._repository);

  /// Imports songs from a JSON file at the given [filePath].
  ///
  /// Returns [SuccessResult] on success, or [FailureResult] with an error
  /// message when the import fails.
  Future<Result<void>> call(String filePath) async {
    return _repository.importSongs(filePath);
  }
}
