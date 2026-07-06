import 'package:flutter/foundation.dart';

import '../../../../core/domain/result.dart';

import '../entities/user.dart';

/// Defines the contract for authentication operations.
///
/// Implementations handle the actual authentication logic,
/// typically delegating to a backend or SDK.
abstract interface class AuthRepository {
  /// Returns a [ValueNotifier] containing the current authentication session state.
  ///
  /// The session contains a [User] when signed in, or [null] when signed out.
  /// This is exposed as a [ValueNotifier] so the UI can reactively watch changes.
  ValueNotifier<User?> get session;

  /// Signs in a user with the given [email] and [password].
  ///
  /// Returns [SuccessResult] on success, or [FailureResult] with an error message
  /// when authentication fails (invalid credentials, user not found, etc.).
  Future<Result<void>> signIn({
    required String email,
    required String password,
  });

  /// Registers a new user with the given [email] and [password].
  ///
  /// Returns [SuccessResult] on success, or [FailureResult] with an error message
  /// when registration fails (email already in use, weak password, etc.).
  Future<Result<void>> signUp({
    required String email,
    required String password,
  });

  /// Signs out the currently signed-in user.
  ///
  /// Returns [SuccessResult] on success, or [FailureResult] if sign-out fails.
  Future<Result<void>> signOut();

  /// Initializes the repository and starts listening for auth state changes.
  ///
  /// Must be called once at app startup via [runAppInitiations].
  Future<void> init();
}
