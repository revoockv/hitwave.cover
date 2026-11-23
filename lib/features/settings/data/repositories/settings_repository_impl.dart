import 'package:flutter/foundation.dart';
import 'package:logger/logger.dart';

import '../../../../core/domain/entities/disposable_resource.dart';
import '../../../../core/domain/entities/result.dart';
import '../../domain/entities/accent_color.dart';
import '../../domain/entities/app_language.dart';
import '../../domain/entities/app_settings.dart';
import '../../domain/entities/app_theme_style.dart';
import '../../domain/entities/settings_failure.dart';
import '../../domain/repositories/settings_repository.dart';
import '../data_sources/hive_settings_service.dart';
import '../models/app_settings_model.dart';

/// [SettingsRepository] on a Hive box.
final class SettingsRepositoryImpl implements SettingsRepository, DisposableResource {
  static const String _saveLog = 'SaveSettings: failure — ';

  final HiveSettingsService _store;
  final Logger _logger;

  final ValueNotifier<AppSettings> _settings = ValueNotifier<AppSettings>(AppSettings.initial);

  /// Creates a [SettingsRepositoryImpl].
  SettingsRepositoryImpl({required this._store, required this._logger});

  /// Loads the stored settings; returns this for `registerSingletonWithDependencies`.
  SettingsRepositoryImpl init() {
    _settings.value = _store.read()?.toEntity() ?? AppSettings.initial;
    return this;
  }

  /// Releases the state.
  @override
  void dispose() {
    _settings.dispose();
  }

  @override
  ValueListenable<AppSettings> watchSettings() => _settings;

  @override
  Future<Result<void, SettingsFailure>> setLanguage(AppLanguage language) =>
      _save(_settings.value.copyWith(language: language));

  @override
  Future<Result<void, SettingsFailure>> setThemeStyle(AppThemeStyle style) =>
      _save(_settings.value.copyWith(themeStyle: style));

  @override
  Future<Result<void, SettingsFailure>> setAccentColor(AccentColor color) =>
      _save(_settings.value.copyWith(accentColor: color));

  /// Shows [settings] at once and stores them.
  Future<Result<void, SettingsFailure>> _save(AppSettings settings) async {
    _settings.value = settings;
    try {
      await _store.write(AppSettingsModel.fromEntity(settings));
      return Result.ok;
    } on Exception catch (e) {
      _logger.e('$_saveLog$e');
      return const Result.failure(SettingsFailure.save);
    }
  }
}
