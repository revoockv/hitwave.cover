import 'package:flutter/foundation.dart' show ValueListenable;

import '../entities/app_settings.dart';
import '../repositories/settings_repository.dart';

/// Use case that exposes the app settings.
final class WatchSettingsUseCase {
  final SettingsRepository _repository;

  /// Creates a [WatchSettingsUseCase].
  WatchSettingsUseCase(this._repository);

  /// Returns the settings; the same instance on every call.
  ValueListenable<AppSettings> call() {
    return _repository.watchSettings();
  }
}
