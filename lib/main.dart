
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:watch_it/watch_it.dart';

import 'di.dart';
import 'features/auth/domain/use_cases/watch_current_session_use_case.dart';
import 'features/auth/presentation/pages/auth_page.dart';
import 'features/song/presentation/pages/home_page.dart';


void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);

  await registerAndInit();

  runApp(const HitwaveCoverApp());
}

/// The root application widget.
///
/// Renders the auth page when not authenticated, or the song page when
/// authenticated.
class HitwaveCoverApp extends WatchingWidget {
  /// Creates a new [HitwaveCoverApp].
  const HitwaveCoverApp({super.key});

  @override
  Widget build(BuildContext context) {
    final user = watchValue((WatchCurrentSessionUseCase watchCurrentUser) => watchCurrentUser());

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: user != null ? const HomePage() : const AuthPage(),
    );
  }
}
