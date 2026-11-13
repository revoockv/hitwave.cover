import 'package:hive_ce/hive_ce.dart';

import '../../../../core/data/data_sources/local_storage_service.dart';
import '../models/app_settings_model.dart';

/// The app settings in their own Hive box.
final class HiveSettingsService {
  static const String _boxName = 'settings';
  static const String _key = 'app';

  final LocalStorageService _storage;

  Box<dynamic>? _box;

  /// Creates the service.
  HiveSettingsService({required this._storage});

  /// Opens the box; returns this for `registerSingletonAsync`.
  Future<HiveSettingsService> init() async {
    _box = await _storage.openBox(_boxName);
    return this;
  }

  /// The stored settings, or `null` before they were first changed.
  AppSettingsModel? read() {
    final Object? value = _box!.get(_key);
    return value is Map<dynamic, dynamic> ? AppSettingsModel.fromMap(value) : null;
  }

  /// Stores [model].
  Future<void> write(AppSettingsModel model) => _box!.put(_key, model.toMap());
}
