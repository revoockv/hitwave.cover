import 'package:flutter/foundation.dart' show ValueNotifier;


import '../entities/user.dart';
import '../repositories/auth_repository.dart';

/// Use case that exposes the current session as a [ValueNotifier].
///
/// Allows the UI to reactively watch session changes (sign in / sign out).
final class WatchCurrentSessionUseCase {
  final AuthRepository _repository;

  /// Creates a new [WatchCurrentSessionUseCase].
  WatchCurrentSessionUseCase(this._repository);

  /// Returns the current session [ValueNotifier].
  ///
  /// Emits [User] when signed in, or [null] when signed out.
  ValueNotifier<User?> call() {
    return _repository.session;
  }
}
