import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;

import 'firebase_options.dart';

/// Firebase backend implementation of the authentication service.
///
/// Wraps the Firebase Auth SDK and provides Stream-based auth state changes
/// along with sign-in/sign-out/sign-up operations.
final class FirebaseAuthService {
  final firebase_auth.FirebaseAuth _firebaseAuth;

  /// Creates a new [FirebaseAuthService].
  ///
  /// [firebaseAuth] is required after [init] is called. Pass
  /// [firebase_auth.FirebaseAuth.instance] from the DI layer.
  FirebaseAuthService({
    required firebase_auth.FirebaseAuth firebaseAuth,
  }) : _firebaseAuth = firebaseAuth;

  /// Initializes Firebase with platform-specific options.
  ///
  /// Must be called before any Firebase operations. Called automatically by
  /// [AuthRepositoryImpl.init].
  static Future<void> init() async {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
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
  /// Throws a [String] error message when authentication fails.
  Future<void> signIn({
    required String email,
    required String password,
  }) async {
    try {
      await _firebaseAuth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
    } on firebase_auth.FirebaseAuthException catch (e) {
      throw _mapFirebaseError(e.code);
    }
  }

  /// Registers a new user with the given [email] and [password].
  ///
  /// Throws a [String] error message when registration fails.
  Future<void> signUp({
    required String email,
    required String password,
  }) async {
    try {
      await _firebaseAuth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
    } on firebase_auth.FirebaseAuthException catch (e) {
      throw _mapFirebaseError(e.code);
    }
  }

  /// Signs out the currently signed-in user.
  ///
  /// Throws a [String] error message when sign-out fails.
  Future<void> signOut() async {
    try {
      await _firebaseAuth.signOut();
    } on firebase_auth.FirebaseAuthException catch (e) {
      throw _mapFirebaseError(e.code);
    }
  }

  /// Returns the currently signed-in Firebase user, or [null] if signed out.
  firebase_auth.User? get currentUser {
    return _firebaseAuth.currentUser;
  }

  /// Maps a Firebase error code to a user-friendly error message.
  String _mapFirebaseError(String code) {
    switch (code) {
      case 'invalid-email':
        return 'Невірний формат email адреси.';
      case 'user-not-found':
        return 'Користувач з таким email не знайдений.';
      case 'wrong-password':
        return 'Невірний пароль.';
      case 'email-already-in-use':
        return 'Цей email вже використовується.';
      case 'weak-password':
        return 'Пароль занадто простий.';
      case 'user-disabled':
        return 'Цей акаунт був відключений.';
      case 'too-many-requests':
        return 'Занадто багато спроб. Спробуйте пізніше.';
      case 'invalid-credential':
        return 'Невірні облікові дані.';
      default:
        return 'Сталася помилка. Спробуйте пізніше.';
    }
  }
}
