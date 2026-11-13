import 'package:flutter/foundation.dart' show ValueListenable;

import '../../../../core/domain/entities/result.dart';
import '../entities/recording_preferences.dart';
import '../entities/recordings_failure.dart';

/// Keeps the recording options of the lyrics page on this device.
abstract interface class RecordingPreferencesRepository {
  /// The options as they were last chosen.
  ValueListenable<RecordingPreferences> watchRecordingPreferences();

  /// Remembers [preferences].
  Future<Result<void, RecordingsFailure>> updateRecordingPreferences(RecordingPreferences preferences);
}
