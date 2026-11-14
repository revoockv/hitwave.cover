import 'package:flutter/foundation.dart' show ValueListenable;

import '../../../../core/domain/entities/result.dart';
import '../entities/imported_recording.dart';
import '../entities/microphone.dart';
import '../entities/recorder_state.dart';
import '../entities/recording.dart';
import '../entities/recordings_failure.dart';

/// Records takes from the microphone and keeps them, with their enhanced versions, on this device.
///
/// Recordings never go to the account; they follow their song when its id changes (moved into
/// the account) and are deleted with it.
abstract interface class RecordingsRepository {
  /// Every recording on the device, newest first.
  ValueListenable<List<Recording>> watchRecordings();

  /// The recorder: idle, or recording a song with the elapsed time and the input level.
  ValueListenable<RecorderState> watchRecorder();

  /// The id of the take the audio engine is enhancing now; `null` when it is idle. Other takes
  /// whose status is enhancing wait in the queue.
  ValueListenable<String?> watchEnhancingRecording();

  /// The sound inputs of the device.
  Future<Result<List<Microphone>, RecordingsFailure>> listMicrophones();

  /// Starts recording a take of [songId] from [microphoneId] (the system input when `null` or
  /// gone); asks for the microphone permission when needed.
  Future<Result<void, RecordingsFailure>> startRecording(String songId, {String? microphoneId});

  /// Stops the take, adds it to the library and starts enhancing it in the background;
  /// [trimSilence] cuts the silence before and after the singing in the enhanced file.
  Future<Result<Recording, RecordingsFailure>> stopRecording({required bool trimSilence});

  /// Enhances the raw take of [recordingId] again (after a failure).
  Future<Result<void, RecordingsFailure>> enhanceAgain({required String recordingId, required bool trimSilence});

  /// Ids of the recordings the user deletes (not those that go with a deleted song).
  Stream<String> watchRecordingDeletions();

  /// Deletes the recording [recordingId] and its files.
  Future<Result<void, RecordingsFailure>> deleteRecording(String recordingId);

  /// Deletes every take of every song, with its files.
  Future<Result<void, RecordingsFailure>> deleteAllRecordings();

  /// Adds [recordings] from a backup or another device to the library, moving their files into
  /// it; a recording whose id is already there is skipped.
  Future<Result<void, RecordingsFailure>> importRecordings(List<ImportedRecording> recordings);
}
