import '../../../../core/domain/entities/result.dart';

import '../repositories/backup_repository.dart';

/// Use case that imports songs from a user-selected JSON file.
///
/// Wraps the repository [importSongs] method as a single-responsibility
/// use case. Returns [Result<void>] indicating success or failure.
/// The file picker is called internally by the repository.
final class ImportSongsUseCase {
  final BackupRepository _repository;

  /// Creates a new [ImportSongsUseCase] use case.
  ImportSongsUseCase(this._repository);

  /// Imports songs from a JSON file selected by the user.
  ///
  /// Prompts the user to select a backup JSON file via file picker,
  /// reads the backup data, and adds all songs to Firebase.
  /// Returns [SuccessResult] on success, or [FailureResult] with an error
  /// message when the import fails.
  Future<Result<void>> call() async {
    return _repository.importSongs();
  }
}
