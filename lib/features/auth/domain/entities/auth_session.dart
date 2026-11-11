import 'user.dart';

/// Who uses the app now: nobody yet, a guest without an account, or a signed-in user.
sealed class AuthSession {
  const AuthSession();
}

/// Nobody has chosen yet: the sign-in screen is shown.
final class SignedOutAuthSession extends AuthSession {
  /// Creates the signed-out session.
  const SignedOutAuthSession();
}

/// The app is used without an account; the songs live on this device.
final class GuestAuthSession extends AuthSession {
  /// Creates the guest session.
  const GuestAuthSession();
}

/// A [user] is signed in; the songs live in their account.
final class SignedInAuthSession extends AuthSession {
  /// The signed-in user.
  final User user;

  /// Creates the session of [user].
  const SignedInAuthSession(this.user);
}
