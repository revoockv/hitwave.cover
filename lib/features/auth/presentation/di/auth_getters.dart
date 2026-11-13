import 'package:watch_it/watch_it.dart';

import '../../domain/use_cases/sign_in_use_case.dart';
import '../../domain/use_cases/sign_out_use_case.dart';
import '../../domain/use_cases/sign_up_use_case.dart';
import '../../domain/use_cases/watch_current_session_use_case.dart';

/// The use case that signs a user in.
SignInUseCase get signInUseCase => di<SignInUseCase>();

/// The use case that registers a new user.
SignUpUseCase get signUpUseCase => di<SignUpUseCase>();

/// The use case that signs the current user out.
SignOutUseCase get signOutUseCase => di<SignOutUseCase>();

/// The use case that watches the session; call it to get the [ValueListenable].
WatchCurrentSessionUseCase get watchCurrentSessionUseCase => di<WatchCurrentSessionUseCase>();
