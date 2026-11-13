import 'app_language.dart';

/// The app settings, kept on this device.
final class AppSettings {
  /// The settings of a first start: English.
  static const AppSettings initial = AppSettings(language: AppLanguage.english);

  /// The language of the app.
  final AppLanguage language;

  /// Creates [AppSettings].
  const AppSettings({required this.language});

  /// A copy with [language] changed.
  AppSettings copyWith({AppLanguage? language}) => AppSettings(language: language ?? this.language);
}
