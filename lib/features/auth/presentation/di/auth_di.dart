import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:flutter/foundation.dart' show ValueNotifier;
import 'package:get_it/get_it.dart';

import '../../data/datasources/firebase_auth_service.dart';
import '../../data/repositories/auth_repository_impl.dart';
import '../../domain/entities/user.dart';
import '../../domain/repositories/auth_repository.dart';
import '../../domain/use_cases/sign_in_use_case.dart';
import '../../domain/use_cases/sign_out_use_case.dart';
import '../../domain/use_cases/sign_up_use_case.dart';
import '../../domain/use_cases/watch_current_session_use_case.dart';

/// Registers all auth feature dependencies in GetIt.
///
/// Creates singleton instances for the Firebase auth service and the auth
/// repository implementation, then registers the session ValueNotifier with
/// the instance key `auth.session`. Calls [FirebaseAuthService.init] to
/// initialize Firebase before the repository starts listening for changes.
Future<void> registerAuthFeature() async {
  final getIt = GetIt.instance;

  await FirebaseAuthService.init();
  await firebase_auth.FirebaseAuth.instance.setSettings(
    appVerificationDisabledForTesting: true,
  );

  getIt.registerSingleton<FirebaseAuthService>(
    FirebaseAuthService(
      firebaseAuth: firebase_auth.FirebaseAuth.instance,
    ),
  );

  final repository = AuthRepositoryImpl(
    getIt<FirebaseAuthService>(),
    getIt.get(),
  );

  getIt.registerSingleton<AuthRepository>(
    repository,
  );

  getIt.registerSingleton<ValueNotifier<User?>>(
    repository.session,
    instanceName: 'auth.session',
  );

  getIt.registerSingleton<SignInUseCase>(SignInUseCase(repository));
  getIt.registerSingleton<SignUpUseCase>(SignUpUseCase(repository));
  getIt.registerSingleton<SignOutUseCase>(SignOutUseCase(repository));
  getIt.registerSingleton<WatchCurrentSessionUseCase>(
    WatchCurrentSessionUseCase(repository),
  );
}
