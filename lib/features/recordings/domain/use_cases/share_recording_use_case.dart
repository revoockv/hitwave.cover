import '../../../../core/domain/entities/result.dart';
import '../entities/recording.dart';
import '../entities/recording_version.dart';
import '../repositories/recording_files_repository.dart';

/// Use case that sends a recording through the share sheet (a messenger, mail…).
final class ShareRecordingUseCase {
  final RecordingFilesRepository _repository;

  /// Creates a [ShareRecordingUseCase].
  ShareRecordingUseCase(this._repository);

  /// Shares the [version] of [recording], with the song [title].
  Future<Result<void>> call({required Recording recording, required RecordingVersion version, String? title}) async {
    return _repository.shareRecording(recording: recording, version: version, title: title);
  }
}
