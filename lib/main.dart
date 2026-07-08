import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:watch_it/watch_it.dart';

import 'core/presentation/di/core_di.dart';
import 'features/auth/domain/repositories/auth_repository.dart';
import 'features/auth/domain/use_cases/watch_current_session_use_case.dart';
import 'features/auth/presentation/di/auth_di.dart';
import 'features/auth/presentation/pages/auth_page.dart';
import 'features/song/domain/repositories/song_repository.dart';
import 'features/song/presentation/di/song_di.dart';
import 'features/song/presentation/pages/home_page.dart';
import 'features/backup/presentation/di/backup_di.dart';

/// App-wide GetIt instance for dependency injection.
final getIt = GetIt.instance;

/// Registers all application dependencies before running the app.
///
/// Registers core dependencies (Logger) first, then all feature dependencies.
Future<void> registerAppDependencies() async {
  await getIt.reset(); // Await the reset just in case

  await registerCoreDI();
  await registerAuthFeature();
  await registerSongFeature();
  await registerBackupFeature();

  // Force GetIt to ensure all singletons are completely instantiated
  await getIt.allReady();
}

/// Runs all one-time initialization tasks at app startup.
///
/// Starts repository subscriptions that feed ValueNotifiers for reactive UI
/// updates.
Future<void> runAppInitiations() async {
  final authRepository = getIt<AuthRepository>();
  await authRepository.init();

  final songRepository = getIt<SongRepository>();
  await songRepository.init();
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);

  await registerAppDependencies();
  await runAppInitiations();

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
