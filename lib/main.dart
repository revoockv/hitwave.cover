import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:watch_it/watch_it.dart';

import 'core/presentation/l10n/app_translations.dart';
import 'core/presentation/theme.dart';
import 'core/presentation/widgets/app_frame_widget.dart';
import 'di.dart';
import 'features/settings/domain/entities/app_settings.dart';
import 'features/settings/presentation/di/settings_getters.dart';
import 'features/settings/presentation/l10n/settings_texts.dart';
import 'features/home/presentation/pages/home_page.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await registerAndInit();

  runApp(const HitwaveCoverAppWidget());
}

/// The root application widget.
///
/// Renders the home page in the language and the look of the settings.
final class HitwaveCoverAppWidget extends WatchingWidget {
  /// Texts of the app first, then Flutter's own; the fallbacks give Interslavic English system texts.
  static const List<LocalizationsDelegate<Object>> _localizationsDelegates = <LocalizationsDelegate<Object>>[
    TranslationsDelegate(),
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
    FallbackMaterialLocalizationsDelegate(),
    FallbackCupertinoLocalizationsDelegate(),
  ];

  /// Creates the app.
  const HitwaveCoverAppWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final AppSettings settings = watch(watchSettingsUseCase()).value;

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      onGenerateTitle: _title,
      locale: settings.language.appLocale.flutterLocale,
      supportedLocales: AppLocaleUtils.supportedLocales,
      localizationsDelegates: _localizationsDelegates,
      theme: settings.themeStyle.theme(settings.accentColor),
      // A new theme or accent flows into the old one; a new language fades in.
      themeAnimationDuration: AppTheme.themeChange,
      themeAnimationCurve: AppTheme.themeChangeCurve,
      builder: AppFrameWidget.wrap,
      home: const HomePage(),
    );
  }

  static String _title(BuildContext context) => context.t.appTitle;
}
