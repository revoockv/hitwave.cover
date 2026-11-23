import 'package:flutter/foundation.dart';
import 'package:logger/logger.dart';

import '../../../../core/domain/entities/disposable_resource.dart';
import '../../../../core/domain/entities/result.dart';
import '../../domain/entities/recording_preferences.dart';
import '../../domain/repositories/recording_preferences_repository.dart';
import '../data_sources/hive_recording_preferences_service.dart';
import '../models/recording_preferences_model.dart';
import '../../domain/entities/recordings_failure.dart';

/// [RecordingPreferencesRepository] on a Hive box.
final class RecordingPreferencesRepositoryImpl implements RecordingPreferencesRepository, DisposableResource {
  static const String _saveLog = 'UpdateRecordingPreferences: failure — ';

  final HiveRecordingPreferencesService _store;
  final Logger _logger;

  final ValueNotifier<RecordingPreferences> _preferences = ValueNotifier<RecordingPreferences>(
    RecordingPreferences.initial,
  );

  /// Creates a [RecordingPreferencesRepositoryImpl].
  RecordingPreferencesRepositoryImpl({required this._store, required this._logger});

  /// Loads the stored options; returns this for `registerSingletonAsync`.
  RecordingPreferencesRepositoryImpl init() {
    _preferences.value = _store.read()?.toEntity() ?? RecordingPreferences.initial;
    return this;
  }

  /// Releases the state.
  @override
  void dispose() {
    _preferences.dispose();
  }

  @override
  ValueListenable<RecordingPreferences> watchRecordingPreferences() => _preferences;

  @override
  Future<Result<void, RecordingsFailure>> updateRecordingPreferences(RecordingPreferences preferences) async {
    _preferences.value = preferences;
    try {
      await _store.write(RecordingPreferencesModel.fromEntity(preferences));
      return Result.ok;
    } on Exception catch (e) {
      _logger.e('$_saveLog$e');
      return const Result.failure(RecordingsFailure.savePreferences);
    }
  }
}
