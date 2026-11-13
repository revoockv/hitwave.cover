import '../../domain/entities/app_language.dart';
import '../../domain/entities/app_settings.dart';

/// The app settings as stored in Hive.
final class AppSettingsModel {
  static const String _languageField = 'language';

  /// Name of the [AppLanguage], so a stored value survives reordering the enum.
  final String language;

  /// Creates an [AppSettingsModel].
  const AppSettingsModel({required this.language});

  /// Reads a stored map.
  factory AppSettingsModel.fromMap(Map<dynamic, dynamic> map) =>
      AppSettingsModel(language: map[_languageField] as String? ?? AppSettings.initial.language.name);

  /// The model of [settings].
  factory AppSettingsModel.fromEntity(AppSettings settings) => AppSettingsModel(language: settings.language.name);

  /// The map to store.
  Map<String, dynamic> toMap() => <String, dynamic>{_languageField: language};

  /// The settings; an unknown language is the first-start one.
  AppSettings toEntity() =>
      AppSettings(language: AppLanguage.values.asNameMap()[language] ?? AppSettings.initial.language);
}
