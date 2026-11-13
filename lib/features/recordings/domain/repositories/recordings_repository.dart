import 'package:flutter/foundation.dart' show ValueListenable;

import '../../../../core/domain/entities/result.dart';
import '../entities/imported_recording.dart';
import '../entities/recorder_state.dart';
import '../entities/recording.dart';

/// Records takes from the microphone and keeps them, with their enhanced versions, on this device.
///
/// Recordings never go to the account; they follow their song when its id changes (moved into
/// the account) and are deleted with it.
abstract interface class RecordingsRepository {
  /// Every recording on the device, newest first.
  ValueListenable<List<Recording>> watchRecordings();

  /// The recorder: idle, or recording a song with the elapsed time and the input level.
  ValueListenable<RecorderState> watchRecorder();

  /// Starts recording a take of [songId]; asks for the microphone permission when needed.
  Future<Result<void>> startRecording(String songId);

  /// Stops the take, adds it to the library and starts enhancing it in the background;
  /// [trimSilence] cuts the silence before and after the singing in the enhanced file.
  Future<Result<Recording>> stopRecording({required bool trimSilence});

  /// Enhances the raw take of [recordingId] again (after a failure).
  Future<Result<void>> enhanceAgain({required String recordingId, required bool trimSilence});

  /// Deletes the recording [recordingId] and its files.
  Future<Result<void>> deleteRecording(String recordingId);

  /// Adds [recordings] from a backup to the library, moving their files into it.
  Future<Result<void>> importRecordings(List<ImportedRecording> recordings);
}
