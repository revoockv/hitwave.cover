import 'package:flutter/foundation.dart' show ValueListenable;

import '../../../../core/domain/entities/result.dart';
import '../entities/practice_session.dart';
import '../entities/practice_failure.dart';

/// Measures how long the songs are practised and keeps the sessions on this device.
///
/// Sessions follow their song when its id changes and are deleted with it.
abstract interface class PracticeRepository {
  /// Every session, newest first.
  ValueListenable<List<PracticeSession>> watchSessions();

  /// Starts measuring the practice of [songId]; nothing happens while that song is already
  /// measured, and the session of another song ends first.
  Future<Result<void, PracticeFailure>> startPractice(String songId);

  /// Ends the session being measured and keeps it when it lasted long enough to count.
  Future<Result<void, PracticeFailure>> stopPractice();

  /// Adds [sessions] from another device; a session whose id is already here is skipped.
  Future<Result<void, PracticeFailure>> importSessions(List<PracticeSession> sessions);

  /// Deletes the session [sessionId]; a synchronisation does not bring it back. Nothing happens
  /// when there is no such session.
  Future<Result<void, PracticeFailure>> deleteSession(String sessionId);

  /// Forgets every practice session.
  Future<Result<void, PracticeFailure>> clearSessions();
}
