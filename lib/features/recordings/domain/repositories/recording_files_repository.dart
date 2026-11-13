import '../../../../core/domain/entities/result.dart';
import '../entities/recording.dart';
import '../entities/recording_version.dart';

/// Hands the WAV files of a recording to the system: the share sheet (messengers, mail…) and the
/// file manager of the desktop.
abstract interface class RecordingFilesRepository {
  /// Opens the share sheet with the [version] of [recording]; [title] (the song) goes with it.
  Future<Result<void>> shareRecording({
    required Recording recording,
    required RecordingVersion version,
    required String? title,
  });

  /// Whether the folder of a recording can be opened here (desktop only).
  bool canShowInFolder();

  /// Opens the folder that holds the files of [recording] in the file manager.
  Future<Result<void>> showInFolder(Recording recording);
}
