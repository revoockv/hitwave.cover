/// What can go wrong with signing in; the presentation layer turns it into text.
enum AuthFailure {
  /// The email or the password is not entered.
  emptyFields,

  /// The email is not an email address.
  invalidEmail,

  /// No account has this email.
  userNotFound,

  /// The password is wrong.
  wrongPassword,

  /// An account with this email already exists.
  emailAlreadyInUse,

  /// The password is too simple.
  weakPassword,

  /// The account is disabled.
  userDisabled,

  /// Too many attempts in a short time.
  tooManyRequests,

  /// The email and the password do not match.
  invalidCredential,

  /// Signing out failed.
  signOut,

  /// Anything else.
  unknown,
}
