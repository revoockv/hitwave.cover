import '../../../../core/domain/entities/result.dart';
import '../entities/recording.dart';
import '../entities/recording_version.dart';
import '../entities/shared_song.dart';

/// Hands the WAV files of a recording to the system: the share sheet (messengers, mail…) and the
/// file manager of the desktop.
abstract interface class RecordingFilesRepository {
  /// Opens the share sheet with the [version] of [recording], named after its [song] (when known).
  Future<Result<void>> shareRecording({
    required Recording recording,
    required RecordingVersion version,
    required SharedSong? song,
  });

  /// Whether the folder of a recording can be opened here (desktop only).
  bool canShowInFolder();

  /// Opens the folder that holds the files of [recording] in the file manager.
  Future<Result<void>> showInFolder(Recording recording);
}
