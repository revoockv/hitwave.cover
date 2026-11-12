import 'package:flutter/foundation.dart' show ValueListenable;

import '../../../../core/domain/entities/result.dart';
import '../entities/practice_session.dart';

/// Measures how long the songs are practised and keeps the sessions on this device.
///
/// Sessions follow their song when its id changes and are deleted with it.
abstract interface class PracticeRepository {
  /// Every session, newest first.
  ValueListenable<List<PracticeSession>> watchSessions();

  /// Starts measuring the practice of [songId]; nothing happens while that song is already
  /// measured, and the session of another song ends first.
  Future<Result<void>> startPractice(String songId);

  /// Ends the session being measured and keeps it when it lasted long enough to count.
  Future<Result<void>> stopPractice();

  /// Adds [sessions] from another device; a session whose id is already here is skipped.
  Future<Result<void>> importSessions(List<PracticeSession> sessions);
}
