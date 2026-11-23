import 'package:flutter/foundation.dart' show ValueListenable;

import '../entities/practice_session.dart';
import '../repositories/practice_repository.dart';

/// Use case that exposes every practice session, newest first.
final class WatchPracticeSessionsUseCase {
  final PracticeRepository _repository;

  /// Creates a [WatchPracticeSessionsUseCase].
  WatchPracticeSessionsUseCase(this._repository);

  /// Returns the sessions.
  ValueListenable<List<PracticeSession>> call() {
    return _repository.watchSessions();
  }
}
