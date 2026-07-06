import '../../../../core/domain/result.dart';

import '../repositories/auth_repository.dart';

/// Use case for signing in a user.
///
/// Wraps the repository [signIn] method as a single-responsibility use case.
/// Returns [Result<void>] indicating success or failure.
final class SignIn {
  final AuthRepository _repository;

  /// Creates a new [SignIn] use case.
  SignIn(this._repository);

  /// Signs in a user with the given [email] and [password].
  ///
  /// Returns [SuccessResult] when credentials are valid, or [FailureResult]
  /// with an error message when authentication fails.
  Future<Result<void>> call({
    required String email,
    required String password,
  }) async {
    return _repository.signIn(email: email, password: password);
  }
}
