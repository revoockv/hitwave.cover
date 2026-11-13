import 'package:flutter/foundation.dart' show ValueListenable;

import '../entities/auth_session.dart';
import '../repositories/auth_repository.dart';

/// Use case that exposes the current session as a [ValueListenable].
///
/// Allows the UI to reactively watch session changes (sign in, guest, sign out).
final class WatchCurrentSessionUseCase {
  final AuthRepository _repository;

  /// Creates a new [WatchCurrentSessionUseCase].
  WatchCurrentSessionUseCase(this._repository);

  /// Returns the current session [ValueListenable].
  ///
  /// Holds the signed-out, guest or signed-in session.
  ValueListenable<AuthSession> call() {
    return _repository.watchSession();
  }
}
