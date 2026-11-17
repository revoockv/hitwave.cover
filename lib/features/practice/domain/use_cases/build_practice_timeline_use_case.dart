import '../../../recordings/domain/entities/recording.dart';
import '../entities/practice_entry.dart';
import '../entities/practice_entry_filter.dart';
import '../entities/practice_session.dart';

/// Puts the practice sessions and the takes into one timeline, the newest first.
final class BuildPracticeTimelineUseCase {
  /// Creates a [BuildPracticeTimelineUseCase].
  const BuildPracticeTimelineUseCase();

  /// The items of [sessions] and [recordings] that [filter] lets through, the newest first.
  List<PracticeEntry> call({
    required List<PracticeSession> sessions,
    required List<Recording> recordings,
    required PracticeEntryFilter filter,
  }) {
    final List<PracticeEntry> entries = PracticeEntry.listOf(sessions: sessions, recordings: recordings);
    return switch (filter) {
      PracticeEntryFilter.all => entries,
      PracticeEntryFilter.practiceOnly => entries.where(_hasNoTakes).toList(),
      PracticeEntryFilter.withTakes => entries.where(_hasTakes).toList(),
    };
  }

  static bool _hasTakes(PracticeEntry entry) => entry.hasTakes;

  static bool _hasNoTakes(PracticeEntry entry) => !entry.hasTakes;
}
