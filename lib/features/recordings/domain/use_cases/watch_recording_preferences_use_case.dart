import 'package:flutter/foundation.dart' show ValueListenable;

import '../entities/recording_preferences.dart';
import '../repositories/recording_preferences_repository.dart';

/// Use case that exposes the remembered recording options.
final class WatchRecordingPreferencesUseCase {
  final RecordingPreferencesRepository _repository;

  /// Creates a [WatchRecordingPreferencesUseCase].
  WatchRecordingPreferencesUseCase(this._repository);

  /// Returns the options.
  ValueListenable<RecordingPreferences> call() {
    return _repository.watchRecordingPreferences();
  }
}
