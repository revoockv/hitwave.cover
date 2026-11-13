import '../../../../core/presentation/l10n/app_translations.dart';
import '../../domain/entities/app_language.dart';
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
