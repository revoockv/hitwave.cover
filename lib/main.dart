import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:watch_it/watch_it.dart';

import 'core/presentation/l10n/app_translations.dart';
import 'core/presentation/theme.dart';
import 'di.dart';
import 'features/auth/domain/entities/auth_session.dart';
import 'features/auth/presentation/di/auth_getters.dart';
import 'features/auth/presentation/pages/auth_page.dart';
import 'features/settings/domain/entities/app_settings.dart';
import 'features/settings/presentation/di/settings_getters.dart';
import 'features/settings/presentation/l10n/settings_texts.dart';
import 'features/song/presentation/pages/home_page.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);

  await registerAndInit();

  runApp(const HitwaveCoverAppWidget());
}

/// The root application widget.
///
/// Renders the auth page while nobody is signed in, or the home page for a
/// signed-in user and for a guest without an account, in the language of the settings.
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

  /// Key of the home page of a guest, so a sign-in builds a fresh home page.
  static const String _guestHomeKey = 'guest';

  /// Creates the app.
  const HitwaveCoverAppWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final AuthSession session = watch(watchCurrentSessionUseCase()).value;
    final AppSettings settings = watch(watchSettingsUseCase()).value;

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      onGenerateTitle: _title,
      locale: settings.language.appLocale.flutterLocale,
      supportedLocales: AppLocaleUtils.supportedLocales,
      localizationsDelegates: _localizationsDelegates,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      home: switch (session) {
        SignedOutAuthSession() => const AuthPage(),
        GuestAuthSession() => const HomePage(key: ValueKey<String>(_guestHomeKey)),
        SignedInAuthSession(:final user) => HomePage(key: ValueKey<String>(user.id)),
      },
    );
  }

  static String _title(BuildContext context) => context.t.appTitle;
}
