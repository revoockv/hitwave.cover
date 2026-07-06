import '../../../../core/domain/result.dart';

import '../repositories/auth_repository.dart';

/// Use case for signing out the current user.
///
/// Wraps the repository [signOut] method as a single-responsibility use case.
/// Returns [Result<void>] indicating success or failure.
final class SignOut {
  final AuthRepository _repository;

  /// Creates a new [SignOut] use case.
  SignOut(this._repository);

  /// Signs out the currently signed-in user.
  ///
  /// Returns [SuccessResult] when sign-out succeeds, or [FailureResult]
  /// with an error message when sign-out fails.
  Future<Result<void>> call() async {
    return _repository.signOut();
  }
}
