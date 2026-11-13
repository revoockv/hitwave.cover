import 'package:flutter/foundation.dart' show ValueListenable;

import '../../../../core/domain/entities/result.dart';
import '../entities/accent_color.dart';
import '../entities/app_language.dart';
import '../entities/app_settings.dart';
import '../entities/app_theme_style.dart';
import '../entities/settings_failure.dart';

/// Keeps the app settings on this device.
abstract interface class SettingsRepository {
  /// The settings as they were last chosen; always the same instance.
  ValueListenable<AppSettings> watchSettings();

  /// Remembers [language] as the language of the app.
  Future<Result<void, SettingsFailure>> setLanguage(AppLanguage language);

  /// Remembers [style] as the look of the app.
  Future<Result<void, SettingsFailure>> setThemeStyle(AppThemeStyle style);

  /// Remembers [color] as the main color of the app.
  Future<Result<void, SettingsFailure>> setAccentColor(AccentColor color);
}
