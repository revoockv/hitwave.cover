import '../../../../core/domain/entities/result.dart';

import '../repositories/auth_repository.dart';
import '../entities/auth_failure.dart';

/// Use case for using the app without an account; the songs stay on the device.
final class ContinueWithoutAccountUseCase {
  final AuthRepository _repository;

  /// Creates a new [ContinueWithoutAccountUseCase] use case.
  ContinueWithoutAccountUseCase(this._repository);

  /// Starts a guest session that is remembered until the user signs in or leaves it.
  Future<Result<void, AuthFailure>> call() async {
    return _repository.continueWithoutAccount();
  }
}
