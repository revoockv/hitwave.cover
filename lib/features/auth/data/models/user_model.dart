import '../../domain/entities/user.dart';

/// Data transfer object representing a user from Firebase.
///
/// Maps between Firebase user properties and the domain [User] entity.
final class UserModel {
  /// The unique identifier for the user.
  final String id;

  /// The email address associated with the user account.
  final String email;

  /// The display name of the user, if set.
  final String? displayName;

  /// The URL of the user's profile picture, if set.
  final String? photoURL;

  /// Creates a new [UserModel] instance.
  const UserModel({
    required this.id,
    required this.email,
    this.displayName,
    this.photoURL,
  });

  /// Converts this model to a domain [User] entity.
  User toEntity() {
    return User(
      id: id,
      email: email,
      displayName: displayName,
      photoURL: photoURL,
    );
  }

  /// Creates a [UserModel] from a domain [User] entity.
  static UserModel fromEntity(User entity) {
    return UserModel(
      id: entity.id,
      email: entity.email,
      displayName: entity.displayName,
      photoURL: entity.photoURL,
    );
  }
}
