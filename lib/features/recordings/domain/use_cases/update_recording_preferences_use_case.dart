import '../../../../core/domain/entities/result.dart';
import '../entities/recording_preferences.dart';
import '../repositories/recording_preferences_repository.dart';
import '../entities/recordings_failure.dart';

/// Use case that remembers the recording options of the lyrics page.
final class UpdateRecordingPreferencesUseCase {
  final RecordingPreferencesRepository _repository;

  /// Creates an [UpdateRecordingPreferencesUseCase].
  UpdateRecordingPreferencesUseCase(this._repository);

  /// Remembers [preferences].
  Future<Result<void, RecordingsFailure>> call(RecordingPreferences preferences) async {
    return _repository.updateRecordingPreferences(preferences);
  }
}
