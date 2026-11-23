import '../../../recordings/domain/entities/recording.dart';
import '../entities/practice_session.dart';
import '../entities/practice_stats.dart';

/// Use case that counts the totals, streaks and calendar of the practice.
final class CalculatePracticeStatsUseCase {
  /// Creates a [CalculatePracticeStatsUseCase].
  const CalculatePracticeStatsUseCase();

  /// Counts [sessions] and the takes ([recordings]) as of [now] (the current time by default).
  PracticeStats call({required List<PracticeSession> sessions, required List<Recording> recordings, DateTime? now}) {
    return PracticeStats.from(sessions: sessions, recordings: recordings, now: now ?? DateTime.now());
  }
}
