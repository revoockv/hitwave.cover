import 'package:logger/logger.dart';
import 'package:watch_it/watch_it.dart';

import '../../../../core/presentation/di/core_di.dart';
import '../../data/data_sources/firebase_auth_service.dart';
import '../../data/repositories/auth_repository_impl.dart';
import '../../domain/repositories/auth_repository.dart';
import '../../domain/use_cases/sign_in_use_case.dart';
import '../../domain/use_cases/sign_out_use_case.dart';
import '../../domain/use_cases/sign_up_use_case.dart';
import '../../domain/use_cases/watch_current_session_use_case.dart';

/// Registers the auth feature and starts its async initialization.
///
/// [FirebaseAuthService.init] initializes Firebase for the whole app, so every
/// feature that uses Firebase depends on [AuthRepository].
void registerAndInitAuth() {
  // 1. data sources — async init: initializes Firebase
  di.registerSingletonAsync<FirebaseAuthService>(() => FirebaseAuthService().init());

  // 2. repositories — async init: subscribes to auth state changes
  di.registerSingletonAsync<AuthRepository>(
    () => AuthRepositoryImpl(authService: di<FirebaseAuthService>(), logger: di<Logger>()).init(),
    dependsOn: <Type>[FirebaseAuthService],
    dispose: disposeResource,
  );

  // 3. use cases
  di.registerLazySingleton<SignInUseCase>(() => SignInUseCase(di<AuthRepository>()));
  di.registerLazySingleton<SignUpUseCase>(() => SignUpUseCase(di<AuthRepository>()));
  di.registerLazySingleton<SignOutUseCase>(() => SignOutUseCase(di<AuthRepository>()));
  di.registerLazySingleton<WatchCurrentSessionUseCase>(() => WatchCurrentSessionUseCase(di<AuthRepository>()));
}
