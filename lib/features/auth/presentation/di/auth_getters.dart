import 'package:flutter/foundation.dart' show ValueNotifier;
import 'package:get_it/get_it.dart';
import 'package:hitwave.cover/features/auth/domain/entities/user.dart';
import 'package:hitwave.cover/features/auth/domain/use_cases/sign_in_use_case.dart';
import 'package:hitwave.cover/features/auth/domain/use_cases/sign_out_use_case.dart';
import 'package:hitwave.cover/features/auth/domain/use_cases/sign_up_use_case.dart';
import 'package:hitwave.cover/features/auth/domain/use_cases/watch_current_session_use_case.dart';
import 'package:watch_it/watch_it.dart';



/// Returns the sign-in use case.
SignInUseCase get signInUseCase {
  return GetIt.instance<SignInUseCase>();
}

/// Returns the sign-up use case.
SignUpUseCase get signUpUseCase {
  return GetIt.instance<SignUpUseCase>();
}

/// Returns the sign-out use case.
SignOutUseCase get signOutUseCase {
  return GetIt.instance<SignOutUseCase>();
}

/// Returns the watch current session use case.
///
/// Use this getter in UI widgets to reactively watch the authentication session.
ValueNotifier<User?> get watchCurrentSessionUseCase {
  return GetIt.instance<WatchCurrentSessionUseCase>()();
}
