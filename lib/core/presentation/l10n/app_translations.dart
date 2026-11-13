import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'strings.g.dart';

export 'package:slang_flutter/slang_flutter.dart' show ExtAppLocale;
export 'strings.g.dart' show AppLocale, AppLocaleUtils, Translations;

/// The [Translations] of the app language, for every widget below `MaterialApp`.
extension TranslationsContext on BuildContext {
  /// The strings of the current language; a widget that reads them rebuilds when the language changes.
  Translations get t => Localizations.of<Translations>(this, Translations)!;
}

/// Loads the [Translations] of a locale into `Localizations`.
final class TranslationsDelegate extends LocalizationsDelegate<Translations> {
  /// Creates the delegate.
  const TranslationsDelegate();

  @override
  bool isSupported(Locale locale) => AppLocaleUtils.supportedLocalesRaw.contains(locale.languageCode);

  @override
  Future<Translations> load(Locale locale) {
    final AppLocale appLocale = AppLocaleUtils.parseLocaleParts(languageCode: locale.languageCode);
    return SynchronousFuture<Translations>(
      appLocale.buildSync(cardinalResolver: appLocale == AppLocale.isv ? _slavicCardinal : null),
    );
  }

  @override
  bool shouldReload(TranslationsDelegate old) => false;

  static const int _ten = 10;
  static const int _hundred = 100;
  static const int _teenFrom = 11;
  static const int _teenTo = 14;
  static const int _fewFrom = 2;
  static const int _fewTo = 4;

  /// Slavic plural forms of Interslavic: 1, 21 → one; 2–4, 22–24 → few; 0, 5–20, 25… → many.
  static String _slavicCardinal(
    num n, {
    String? zero,
    String? one,
    String? two,
    String? few,
    String? many,
    String? other,
  }) {
    if (n is! int) return other!;
    final int lastDigit = n % _ten;
    final int lastTwo = n % _hundred;
    final bool isTeen = lastTwo >= _teenFrom && lastTwo <= _teenTo;
    if (lastDigit == 1 && !isTeen) return one ?? other!;
    if (lastDigit >= _fewFrom && lastDigit <= _fewTo && !isTeen) return few ?? other!;
    return many ?? other!;
  }
}

/// Material and Cupertino texts in English for the languages Flutter has no texts of (Interslavic).
final class FallbackMaterialLocalizationsDelegate extends LocalizationsDelegate<MaterialLocalizations> {
  /// Creates the delegate.
  const FallbackMaterialLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) => locale.languageCode == AppLocale.isv.languageCode;

  @override
  Future<MaterialLocalizations> load(Locale locale) => DefaultMaterialLocalizations.load(locale);

  @override
  bool shouldReload(FallbackMaterialLocalizationsDelegate old) => false;
}

/// Cupertino texts in English for the languages Flutter has no texts of (Interslavic).
final class FallbackCupertinoLocalizationsDelegate extends LocalizationsDelegate<CupertinoLocalizations> {
  /// Creates the delegate.
  const FallbackCupertinoLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) => locale.languageCode == AppLocale.isv.languageCode;

  @override
  Future<CupertinoLocalizations> load(Locale locale) => DefaultCupertinoLocalizations.load(locale);

  @override
  bool shouldReload(FallbackCupertinoLocalizationsDelegate old) => false;
}
