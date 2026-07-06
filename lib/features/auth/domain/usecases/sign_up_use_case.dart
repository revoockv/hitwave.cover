import '../../../../core/domain/result.dart';

import '../repositories/auth_repository.dart';

/// Use case for registering a new user.
///
/// Wraps the repository [signUp] method as a single-responsibility use case.
/// Returns [Result<void>] indicating success or failure.
final class SignUpUseCase {
  final AuthRepository _repository;

  /// Creates a new [SignUpUseCase] use case.
  SignUpUseCase(this._repository);

  /// Registers a new user with the given [email] and [password].
  ///
  /// Returns [SuccessResult] when registration succeeds, or [FailureResult]
  /// with an error message when registration fails.
  Future<Result<void>> call({
    required String email,
    required String password,
  }) async {
    return _repository.signUp(email: email, password: password);
  }
}
