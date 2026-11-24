import 'package:hive_ce/hive_ce.dart';

import '../../../../core/data/data_sources/local_storage_service.dart';
import '../models/recording_preferences_model.dart';

/// The recording options in their own Hive box.
final class HiveRecordingPreferencesService {
  static const String _boxName = 'recording_preferences';
  static const String _key = 'lyricsPage';

  final LocalStorageService _storage;

  Box<dynamic>? _box;

  /// Creates the service.
  HiveRecordingPreferencesService({required this._storage});

  /// Opens the box; returns this for `registerSingletonAsync`.
  Future<HiveRecordingPreferencesService> init() async {
    _box = await _storage.openBox(_boxName);
    return this;
  }

  /// The stored options, or `null` before they were first changed.
  RecordingPreferencesModel? read() {
    return RecordingPreferencesModel.fromStored(_box!.get(_key));
  }

  /// Stores [model].
  Future<void> write(RecordingPreferencesModel model) => _box!.put(_key, model.toMap());
}
