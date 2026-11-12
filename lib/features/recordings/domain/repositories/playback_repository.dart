import 'package:flutter/foundation.dart' show ValueListenable;

import '../../../../core/domain/entities/result.dart';
import '../entities/playback_state.dart';
import '../entities/recording.dart';
import '../entities/recording_version.dart';

/// Plays recordings, one at a time.
abstract interface class PlaybackRepository {
  /// What is playing.
  ValueListenable<PlaybackState> watchPlayback();

  /// Plays [version] of [recording] from the start; the original is played over the same part
  /// of the take as the enhanced file, so both can be compared.
  Future<Result<void>> play({required Recording recording, required RecordingVersion version});

  /// Pauses, or continues after a pause.
  Future<Result<void>> togglePause();

  /// Stops and unloads the recording.
  Future<Result<void>> stop();
}
