import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;

import 'firebase_options.dart';

import '../../domain/entities/auth_failure.dart';

/// Firebase backend implementation of the authentication service.
///
/// Wraps the Firebase Auth SDK and provides Stream-based auth state changes
/// along with sign-in/sign-out/sign-up operations.
final class FirebaseAuthService {
  static const String _invalidEmail = 'invalid-email';
  static const String _userNotFound = 'user-not-found';
  static const String _wrongPassword = 'wrong-password';
  static const String _emailAlreadyInUse = 'email-already-in-use';
  static const String _weakPassword = 'weak-password';
  static const String _userDisabled = 'user-disabled';
  static const String _tooManyRequests = 'too-many-requests';
  static const String _invalidCredential = 'invalid-credential';

  /// The Firebase Auth SDK; available after [init].
  firebase_auth.FirebaseAuth get _firebaseAuth => firebase_auth.FirebaseAuth.instance;

  /// Initializes Firebase with platform-specific options; returns this for `registerSingletonAsync`.
  ///
  /// Must finish before any Firebase operation of any feature.
  Future<FirebaseAuthService> init() async {
    await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
    await _firebaseAuth.setSettings(appVerificationDisabledForTesting: true);
    return this;
  }

  /// Returns a Stream of Firebase user changes.
  ///
  /// Emits [firebase_auth.User?] whenever the authentication state changes
  /// (sign in, sign out, token refresh, etc.).
  Stream<firebase_auth.User?> userChanges() {
    return _firebaseAuth.authStateChanges();
  }

  /// Signs in a user with the given [email] and [password].
  ///
  /// Throws an [AuthServiceException] with an [AuthFailure] when authentication fails.
  Future<void> signIn({required String email, required String password}) async {
    try {
      await _firebaseAuth.signInWithEmailAndPassword(email: email, password: password);
    } on firebase_auth.FirebaseAuthException catch (e) {
      throw AuthServiceException(_mapFirebaseError(e.code));
    }
  }

  /// Registers a new user with the given [email] and [password].
  ///
  /// Throws an [AuthServiceException] with an [AuthFailure] when registration fails.
  Future<void> signUp({required String email, required String password}) async {
    try {
      await _firebaseAuth.createUserWithEmailAndPassword(email: email, password: password);
    } on firebase_auth.FirebaseAuthException catch (e) {
      throw AuthServiceException(_mapFirebaseError(e.code));
    }
  }

  /// Signs out the currently signed-in user.
  ///
  /// Throws an [AuthServiceException] with an [AuthFailure] when sign-out fails.
  Future<void> signOut() async {
    try {
      await _firebaseAuth.signOut();
    } on firebase_auth.FirebaseAuthException catch (e) {
      throw AuthServiceException(_mapFirebaseError(e.code));
    }
  }

  /// Returns the currently signed-in Firebase user, or [null] if signed out.
  firebase_auth.User? get currentUser {
    return _firebaseAuth.currentUser;
  }

  /// Maps a Firebase error code to an [AuthFailure].
  AuthFailure _mapFirebaseError(String code) {
    switch (code) {
      case _invalidEmail:
        return AuthFailure.invalidEmail;
      case _userNotFound:
        return AuthFailure.userNotFound;
      case _wrongPassword:
        return AuthFailure.wrongPassword;
      case _emailAlreadyInUse:
        return AuthFailure.emailAlreadyInUse;
      case _weakPassword:
        return AuthFailure.weakPassword;
      case _userDisabled:
        return AuthFailure.userDisabled;
      case _tooManyRequests:
        return AuthFailure.tooManyRequests;
      case _invalidCredential:
        return AuthFailure.invalidCredential;
      default:
        return AuthFailure.unknown;
    }
  }
}

/// A failed auth operation with what went wrong.
final class AuthServiceException implements Exception {
  /// What went wrong.
  final AuthFailure failure;

  /// Creates the exception with [failure].
  const AuthServiceException(this.failure);

  @override
  String toString() => failure.name;
}
