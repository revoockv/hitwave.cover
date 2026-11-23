import 'accent_color.dart';
import 'app_language.dart';
import 'app_theme_style.dart';

/// The app settings, kept on this device.
final class AppSettings {
  /// The settings of a first start: English, light glass, orange.
  static const AppSettings initial = AppSettings(
    language: AppLanguage.english,
    themeStyle: AppThemeStyle.glassLight,
    accentColor: AccentColor.orange,
  );

  /// The language of the app.
  final AppLanguage language;

  /// The look of the app.
  final AppThemeStyle themeStyle;

  /// The main color of the app.
  final AccentColor accentColor;

  /// Creates [AppSettings].
  const AppSettings({required this.language, required this.themeStyle, required this.accentColor});

  /// A copy with the given values changed.
  AppSettings copyWith({AppLanguage? language, AppThemeStyle? themeStyle, AccentColor? accentColor}) => AppSettings(
    language: language ?? this.language,
    themeStyle: themeStyle ?? this.themeStyle,
    accentColor: accentColor ?? this.accentColor,
  );
}
