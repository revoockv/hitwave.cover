import '../../../../core/domain/entities/result.dart';

import '../repositories/auth_repository.dart';
import '../entities/auth_failure.dart';

/// Use case for signing out the current user.
///
/// Wraps the repository [signOut] method as a single-responsibility use case.
/// Returns [Result<void, AuthFailure>] indicating success or failure.
final class SignOutUseCase {
  final AuthRepository _repository;

  /// Creates a new [SignOutUseCase] use case.
  SignOutUseCase(this._repository);

  /// Signs out the currently signed-in user.
  ///
  /// Returns [SuccessResult] when sign-out succeeds, or [FailureResult]
  /// with an error message when sign-out fails.
  Future<Result<void, AuthFailure>> call() async {
    return _repository.signOut();
  }
}
