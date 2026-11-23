import 'package:flutter/material.dart';

import '../../../../core/presentation/l10n/app_translations.dart';
import '../../../../core/presentation/theme.dart';
import '../../domain/entities/accent_color.dart';
import '../../domain/entities/app_language.dart';
import '../../domain/entities/app_theme_style.dart';
import '../../domain/entities/settings_failure.dart';

/// The text of a [SettingsFailure] shown to the user.
extension SettingsFailureText on SettingsFailure {
  /// The text of this failure in the language of [t].
  String text(Translations t) => switch (this) {
    SettingsFailure.save => t.settings.saveFailed,
  };
}

/// How an [AppLanguage] is named and which translations it uses.
extension AppLanguageTexts on AppLanguage {
  static const String _english = 'English';
  static const String _interslavic = 'Меджусловјанскы';

  /// The name of the language in the language itself, so anyone finds their own.
  String get nativeName => switch (this) {
    AppLanguage.english => _english,
    AppLanguage.interslavic => _interslavic,
  };

  /// The translations of the language.
  AppLocale get appLocale => switch (this) {
    AppLanguage.english => AppLocale.en,
    AppLanguage.interslavic => AppLocale.isv,
  };
}

/// How an [AppThemeStyle] is named and drawn.
extension AppThemeStyleTexts on AppThemeStyle {
  /// The name of the look in the language of [t].
  String text(Translations t) => switch (this) {
    AppThemeStyle.glassLight => t.settings.themes.glassLight,
    AppThemeStyle.glassDark => t.settings.themes.glassDark,
    AppThemeStyle.neumorphicLight => t.settings.themes.neumorphicLight,
    AppThemeStyle.neumorphicDark => t.settings.themes.neumorphicDark,
  };

  /// The surfaces of the look.
  SurfaceStyle get surfaceStyle => switch (this) {
    AppThemeStyle.glassLight || AppThemeStyle.glassDark => SurfaceStyle.glass,
    AppThemeStyle.neumorphicLight || AppThemeStyle.neumorphicDark => SurfaceStyle.neumorphic,
  };

  /// Whether the look is light or dark.
  Brightness get brightness => switch (this) {
    AppThemeStyle.glassLight || AppThemeStyle.neumorphicLight => Brightness.light,
    AppThemeStyle.glassDark || AppThemeStyle.neumorphicDark => Brightness.dark,
  };

  /// The theme of the look with [accent] as the main color.
  ThemeData theme(AccentColor accent) =>
      AppTheme.build(style: surfaceStyle, brightness: brightness, accent: accent.color);
}

/// How an [AccentColor] is named and painted.
extension AccentColorTexts on AccentColor {
  /// The name of the color in the language of [t].
  String text(Translations t) => switch (this) {
    AccentColor.orange => t.settings.colors.orange,
    AccentColor.blue => t.settings.colors.blue,
    AccentColor.indigo => t.settings.colors.indigo,
    AccentColor.violet => t.settings.colors.violet,
    AccentColor.pink => t.settings.colors.pink,
    AccentColor.red => t.settings.colors.red,
    AccentColor.green => t.settings.colors.green,
    AccentColor.teal => t.settings.colors.teal,
  };

  /// The color.
  Color get color => switch (this) {
    AccentColor.orange => AppTheme.accentOrange,
    AccentColor.blue => AppTheme.accentBlue,
    AccentColor.indigo => AppTheme.accentIndigo,
    AccentColor.violet => AppTheme.accentViolet,
    AccentColor.pink => AppTheme.accentPink,
    AccentColor.red => AppTheme.accentRed,
    AccentColor.green => AppTheme.accentGreen,
    AccentColor.teal => AppTheme.accentTeal,
  };
}
