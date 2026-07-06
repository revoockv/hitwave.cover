import 'package:flutter/foundation.dart' show ValueNotifier;
import 'package:logger/logger.dart';

import '../../domain/entities/user.dart';
import '../../domain/repositories/auth_repository.dart';
import '../../../../core/domain/result.dart';
import '../datasources/firebase_auth_service.dart';
import '../models/user_model.dart';

/// Firebase-based implementation of [AuthRepository].
///
/// Subscribes to Firebase auth state changes and exposes the current session
/// as a [ValueNotifier<User?]` for reactive UI updates.
final class AuthRepositoryImpl implements AuthRepository {
  final FirebaseAuthService _authService;
  final Logger _logger;

  /// Exposes the current authentication session as a [ValueNotifier].
  ///
  /// Contains a [User] when signed in, or [null] when signed out.
  final ValueNotifier<User?> _session = ValueNotifier(null);

  @override
  ValueNotifier<User?> get session => _session;

  /// Creates a new [AuthRepositoryImpl].
  AuthRepositoryImpl(this._authService, this._logger);

  @override
  Future<void> init() async {
    await FirebaseAuthService.init();
    _logger.i('Auth repository init: subscribed to auth state changes');
    _authService.userChanges().listen((firebaseUser) {
      if (firebaseUser != null) {
        _session.value = UserModel(
          id: firebaseUser.uid,
          email: firebaseUser.email ?? '',
          displayName: firebaseUser.displayName,
          photoURL: firebaseUser.photoURL,
        ).toEntity();
      } else {
        _session.value = null;
      }
    });
  }

  @override
  Future<Result<void>> signIn({
    required String email,
    required String password,
  }) async {
    try {
      _logger.i('SignIn: starting for email="$email"');
      await _authService.signIn(email: email, password: password);
      _logger.i('SignIn: success — user "$email" signed in');
      return Result.success();
    } catch (e) {
      _logger.e('SignIn: failure — $e');
      return Result.failure(e.toString());
    }
  }

  @override
  Future<Result<void>> signUp({
    required String email,
    required String password,
  }) async {
    try {
      _logger.i('SignUp: starting for email="$email"');
      await _authService.signUp(email: email, password: password);
      _logger.i('SignUp: success — user "$email" registered');
      return Result.success();
    } catch (e) {
      _logger.e('SignUp: failure — $e');
      return Result.failure(e.toString());
    }
  }

  @override
  Future<Result<void>> signOut() async {
    try {
      _logger.i('SignOut: starting');
      await _authService.signOut();
      _logger.i('SignOut: success — user signed out');
      return Result.success();
    } catch (e) {
      _logger.e('SignOut: failure — $e');
      return Result.failure(e.toString());
    }
  }
}
