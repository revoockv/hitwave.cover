import '../../../../core/domain/entities/result.dart';

import '../repositories/auth_repository.dart';
import '../entities/auth_failure.dart';

/// Use case for signing in a user.
///
/// Wraps the repository [signIn] method as a single-responsibility use case.
/// Returns [Result<void, AuthFailure>] indicating success or failure.
final class SignInUseCase {
  final AuthRepository _repository;

  /// Creates a new [SignInUseCase] use case.
  SignInUseCase(this._repository);

  /// Signs in a user with the given [email] and [password].
  ///
  /// Returns [SuccessResult] when credentials are valid, or [FailureResult]
  /// with an error message when authentication fails.
  Future<Result<void, AuthFailure>> call({required String email, required String password}) async {
    return _repository.signIn(email: email, password: password);
  }
}
