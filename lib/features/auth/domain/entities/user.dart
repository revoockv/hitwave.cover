/// Represents an authenticated user in the application.
final class User {
  /// The unique identifier for the user.
  final String id;

  /// The email address associated with the user account.
  final String email;

  /// The display name of the user, if set.
  final String? displayName;

  /// The URL of the user's profile picture, if set.
  final String? photoURL;

  /// Creates a new [User] instance.
  const User({
    required this.id,
    required this.email,
    this.displayName,
    this.photoURL,
  });
}
