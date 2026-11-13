import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:watch_it/watch_it.dart';

import 'core/presentation/theme.dart';
import 'di.dart';
import 'features/auth/domain/entities/auth_session.dart';
import 'features/auth/presentation/di/auth_getters.dart';
import 'features/auth/presentation/pages/auth_page.dart';
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
/// signed-in user and for a guest without an account.
final class HitwaveCoverAppWidget extends WatchingWidget {
  /// Title of the app in the task switcher.
  static const String _appTitle = 'Hitwave Cover';

  /// Key of the home page of a guest, so a sign-in builds a fresh home page.
  static const String _guestHomeKey = 'guest';

  /// Creates the app.
  const HitwaveCoverAppWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final AuthSession session = watch(watchCurrentSessionUseCase()).value;

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: _appTitle,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      home: switch (session) {
        SignedOutAuthSession() => const AuthPage(),
        GuestAuthSession() => const HomePage(key: ValueKey<String>(_guestHomeKey)),
        SignedInAuthSession(:final user) => HomePage(key: ValueKey<String>(user.id)),
      },
    );
  }
}
