import 'package:flutter/foundation.dart' show ValueListenable;

import '../../../../core/domain/entities/result.dart';

import '../entities/auth_session.dart';

/// Defines the contract for authentication operations.
///
/// Implementations handle the actual authentication logic,
/// typically delegating to a backend or SDK.
abstract interface class AuthRepository {
  /// The current session: signed out, a guest without an account, or a signed-in user.
  ValueListenable<AuthSession> watchSession();

  /// Starts a guest session that is remembered on the device.
  ///
  /// Returns [Result.ok] on success, or a failure with an error message.
  Future<Result<void>> continueWithoutAccount();

  /// Signs in a user with the given [email] and [password].
  ///
  /// Returns [SuccessResult] on success, or [FailureResult] with an error message
  /// when authentication fails (invalid credentials, user not found, etc.).
  Future<Result<void>> signIn({required String email, required String password});

  /// Registers a new user with the given [email] and [password].
  ///
  /// Returns [SuccessResult] on success, or [FailureResult] with an error message
  /// when registration fails (email already in use, weak password, etc.).
  Future<Result<void>> signUp({required String email, required String password});

  /// Signs out the signed-in user, or leaves the guest session; the sign-in
  /// screen is shown again and the songs on the device are kept.
  ///
  /// Returns [SuccessResult] on success, or [FailureResult] if sign-out fails.
  Future<Result<void>> signOut();
}
