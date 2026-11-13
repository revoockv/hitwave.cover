import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:flutter/foundation.dart';
import 'package:logger/logger.dart';

import '../../../../core/domain/entities/disposable_resource.dart';
import '../../../../core/domain/entities/result.dart';
import '../../domain/entities/auth_session.dart';
import '../../domain/repositories/auth_repository.dart';
import '../data_sources/firebase_auth_service.dart';
import '../data_sources/local_auth_service.dart';
import '../models/user_model.dart';

/// Firebase-based implementation of [AuthRepository] with a guest mode.
///
/// Subscribes to Firebase auth state changes in [init] and keeps the current
/// session in a private [ValueNotifier], exposed as [ValueListenable]. A signed-in
/// Firebase user wins; otherwise the guest flag saved on the device decides
/// between [GuestAuthSession] and [SignedOutAuthSession].
final class AuthRepositoryImpl implements AuthRepository, DisposableResource {
  static const String _genericErrorMessage = 'Сталася помилка. Спробуйте пізніше.';
  static const String _noEmail = '';

  static const String _initLog = 'Auth repository init: subscribed to auth state changes';
  static const String _disposeLog = 'Auth repository dispose: unsubscribed';
  static const String _signInStartLog = 'SignIn: starting for email="';
  static const String _signInSuccessLog = 'SignIn: success — user "';
  static const String _signInFailureLog = 'SignIn: failure — ';
  static const String _signUpStartLog = 'SignUp: starting for email="';
  static const String _signUpSuccessLog = 'SignUp: success — user "';
  static const String _signUpFailureLog = 'SignUp: failure — ';
  static const String _signOutStartLog = 'SignOut: starting';
  static const String _signOutSuccessLog = 'SignOut: success — user signed out';
  static const String _signOutFailureLog = 'SignOut: failure — ';
  static const String _guestStartLog = 'ContinueWithoutAccount: starting';
  static const String _guestSuccessLog = 'ContinueWithoutAccount: success — guest session';
  static const String _guestFailureLog = 'ContinueWithoutAccount: failure — ';
  static const String _closingQuoteLog = '"';

  final FirebaseAuthService _authService;
  final LocalAuthService _localAuthService;
  final Logger _logger;

  final ValueNotifier<AuthSession> _session = ValueNotifier<AuthSession>(const SignedOutAuthSession());

  StreamSubscription<firebase_auth.User?>? _subscription;

  /// Creates a new [AuthRepositoryImpl].
  AuthRepositoryImpl({required this._authService, required this._localAuthService, required this._logger});

  /// Subscribes to Firebase auth state changes; returns this for `registerSingletonAsync`.
  Future<AuthRepositoryImpl> init() async {
    _session.value = _toSession(_authService.currentUser);
    _subscription ??= _authService.userChanges().listen(_onUserChanged);
    _logger.i(_initLog);
    return this;
  }

  /// Cancels the subscription and releases the state.
  @override
  Future<void> dispose() async {
    await _subscription?.cancel();
    _subscription = null;
    _session.dispose();
    _logger.i(_disposeLog);
  }

  @override
  ValueListenable<AuthSession> watchSession() => _session;

  void _onUserChanged(firebase_auth.User? firebaseUser) {
    _session.value = _toSession(firebaseUser);
  }

  AuthSession _toSession(firebase_auth.User? firebaseUser) {
    if (firebaseUser == null) {
      return _localAuthService.isGuest ? const GuestAuthSession() : const SignedOutAuthSession();
    }
    return SignedInAuthSession(
      UserModel(
        id: firebaseUser.uid,
        email: firebaseUser.email ?? _noEmail,
        displayName: firebaseUser.displayName,
        photoURL: firebaseUser.photoURL,
      ).toEntity(),
    );
  }

  @override
  Future<Result<void>> continueWithoutAccount() async {
    _logger.i(_guestStartLog);
    try {
      await _localAuthService.setGuest(true);
      _session.value = _toSession(_authService.currentUser);
      _logger.i(_guestSuccessLog);
      return Result.ok;
    } on Exception catch (e) {
      _logger.e('$_guestFailureLog$e');
      return const Result.failure(_genericErrorMessage);
    }
  }

  @override
  Future<Result<void>> signIn({required String email, required String password}) async {
    _logger.i('$_signInStartLog$email$_closingQuoteLog');
    try {
      await _authService.signIn(email: email, password: password);
      await _localAuthService.setGuest(false);
      _logger.i('$_signInSuccessLog$email$_closingQuoteLog');
      return Result.ok;
    } on AuthServiceException catch (e) {
      _logger.e('$_signInFailureLog$e');
      return Result.failure(e.message);
    } on Exception catch (e) {
      _logger.e('$_signInFailureLog$e');
      return const Result.failure(_genericErrorMessage);
    }
  }

  @override
  Future<Result<void>> signUp({required String email, required String password}) async {
    _logger.i('$_signUpStartLog$email$_closingQuoteLog');
    try {
      await _authService.signUp(email: email, password: password);
      await _localAuthService.setGuest(false);
      _logger.i('$_signUpSuccessLog$email$_closingQuoteLog');
      return Result.ok;
    } on AuthServiceException catch (e) {
      _logger.e('$_signUpFailureLog$e');
      return Result.failure(e.message);
    } on Exception catch (e) {
      _logger.e('$_signUpFailureLog$e');
      return const Result.failure(_genericErrorMessage);
    }
  }

  @override
  Future<Result<void>> signOut() async {
    _logger.i(_signOutStartLog);
    try {
      await _localAuthService.setGuest(false);
      if (_authService.currentUser == null) {
        _session.value = const SignedOutAuthSession();
      } else {
        await _authService.signOut();
      }
      _logger.i(_signOutSuccessLog);
      return Result.ok;
    } on AuthServiceException catch (e) {
      _logger.e('$_signOutFailureLog$e');
      return Result.failure(e.message);
    } on Exception catch (e) {
      _logger.e('$_signOutFailureLog$e');
      return const Result.failure(_genericErrorMessage);
    }
  }
}
