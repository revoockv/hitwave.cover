import '../repositories/recording_files_repository.dart';

/// Use case that tells whether the folder of a recording can be opened on this platform.
final class CanShowRecordingInFolderUseCase {
  final RecordingFilesRepository _repository;

  /// Creates a [CanShowRecordingInFolderUseCase].
  CanShowRecordingInFolderUseCase(this._repository);

  /// Whether "show in folder" is offered.
  bool call() {
    return _repository.canShowInFolder();
  }
}
