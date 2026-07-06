import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get_it/get_it.dart';
import 'package:watch_it/watch_it.dart';

import 'features/auth/domain/repositories/auth_repository.dart';
import 'features/auth/presentation/di/auth_di.dart';
import 'features/auth/presentation/pages/auth_page.dart';
import 'features/song/domain/repositories/song_repository.dart';
import 'features/song/presentation/di/song_di.dart';

/// App-wide GetIt instance for dependency injection.
final getIt = GetIt.instance;

/// Registers all application dependencies before running the app.
Future<void> registerAppDependencies() async {
  getIt.reset();
  await registerAuthFeature();
  await registerSongFeature();
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
/// Renders the auth page after Firebase and GetIt have been initialized.
class HitwaveCoverApp extends StatelessWidget {
  /// Creates a new [HitwaveCoverApp].
  const HitwaveCoverApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: const AuthPage(),
    );
  }
}
