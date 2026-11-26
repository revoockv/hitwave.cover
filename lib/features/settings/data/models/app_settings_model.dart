import '../../domain/entities/accent_color.dart';
import '../../domain/entities/app_language.dart';
import '../../domain/entities/app_settings.dart';
import '../../domain/entities/app_theme_style.dart';

/// The app settings as stored in Hive; enums by name, so a stored value survives reordering them.
final class AppSettingsModel {
  static const String _languageField = 'language';
  static const String _themeStyleField = 'themeStyle';
  static const String _accentColorField = 'accentColor';

  /// Name of the [AppLanguage].
  final String language;

  /// Name of the [AppThemeStyle].
  final String themeStyle;

  /// Name of the [AccentColor].
  final String accentColor;

  /// Creates an [AppSettingsModel].
  const AppSettingsModel({required this.language, required this.themeStyle, required this.accentColor});

  /// Reads what Hive returned: `null` when nothing (or no map) was stored.
  static AppSettingsModel? fromStored(Object? value) =>
      value is Map<dynamic, dynamic> ? AppSettingsModel.fromMap(value) : null;

  /// Reads a stored map; a missing field keeps its first-start value.
  factory AppSettingsModel.fromMap(Map<dynamic, dynamic> map) => AppSettingsModel(
    language: map[_languageField] as String? ?? AppSettings.initial.language.name,
    themeStyle: map[_themeStyleField] as String? ?? AppSettings.initial.themeStyle.name,
    accentColor: map[_accentColorField] as String? ?? AppSettings.initial.accentColor.name,
  );

  /// The model of [settings].
  factory AppSettingsModel.fromEntity(AppSettings settings) => AppSettingsModel(
    language: settings.language.name,
    themeStyle: settings.themeStyle.name,
    accentColor: settings.accentColor.name,
  );

  /// The map to store.
  Map<String, dynamic> toMap() => <String, dynamic>{
    _languageField: language,
    _themeStyleField: themeStyle,
    _accentColorField: accentColor,
  };

  /// The settings; an unknown value is the first-start one.
  AppSettings toEntity() => AppSettings(
    language: AppLanguage.values.asNameMap()[language] ?? AppSettings.initial.language,
    themeStyle: AppThemeStyle.values.asNameMap()[themeStyle] ?? AppSettings.initial.themeStyle,
    accentColor: AccentColor.values.asNameMap()[accentColor] ?? AppSettings.initial.accentColor,
  );
}
