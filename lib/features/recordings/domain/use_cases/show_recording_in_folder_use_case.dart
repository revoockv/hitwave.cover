import '../../../../core/domain/entities/result.dart';
import '../entities/recording.dart';
import '../repositories/recording_files_repository.dart';
import '../entities/recordings_failure.dart';

/// Use case that opens the folder of a recording's files in the file manager.
final class ShowRecordingInFolderUseCase {
  final RecordingFilesRepository _repository;

  /// Creates a [ShowRecordingInFolderUseCase].
  ShowRecordingInFolderUseCase(this._repository);

  /// Opens the folder of [recording].
  Future<Result<void, RecordingsFailure>> call(Recording recording) async {
    return _repository.showInFolder(recording);
  }
}
