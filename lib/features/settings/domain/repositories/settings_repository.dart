import 'package:flutter/foundation.dart' show ValueListenable;

import '../../../../core/domain/entities/result.dart';
import '../entities/app_language.dart';
import '../entities/app_settings.dart';
import '../entities/settings_failure.dart';

/// Keeps the app settings on this device.
abstract interface class SettingsRepository {
  /// The settings as they were last chosen; always the same instance.
  ValueListenable<AppSettings> watchSettings();

  /// Remembers [language] as the language of the app.
  Future<Result<void, SettingsFailure>> setLanguage(AppLanguage language);
}
