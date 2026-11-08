import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:watch_it/watch_it.dart';

import 'core/presentation/theme.dart';
import 'di.dart';
import 'features/auth/domain/entities/user.dart';
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
/// Renders the auth page when not authenticated, or the home page when
/// authenticated.
final class HitwaveCoverAppWidget extends WatchingWidget {
  /// Title of the app in the task switcher.
  static const String _appTitle = 'Hitwave Cover';

  /// Creates the app.
  const HitwaveCoverAppWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final User? user = watch(watchCurrentSessionUseCase()).value;

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: _appTitle,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      home: user != null ? const HomePage() : const AuthPage(),
    );
  }
}
