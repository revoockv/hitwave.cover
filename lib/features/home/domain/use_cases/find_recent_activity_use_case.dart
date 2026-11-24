import '../../../history/domain/entities/usage_history.dart';
import '../../../recordings/domain/entities/recording.dart';
import '../../../song/domain/entities/song.dart';
import '../entities/recent_activity.dart';

/// Finds the songs opened last and the covers played last.
final class FindRecentActivityUseCase {
  /// How many songs and covers are recent.
  static const int recentCount = 5;

  /// Creates a new [FindRecentActivityUseCase].
  const FindRecentActivityUseCase();

  /// The last [recentCount] of [songs] opened and of [recordings] played, by [history], newest first.
  RecentActivity call({required List<Song> songs, required List<Recording> recordings, required UsageHistory history}) {
    final Map<String, Song> songsById = <String, Song>{for (final Song song in songs) song.id: song};
    final List<UsageTime> opened =
        history.songsOpened.where((UsageTime time) => songsById.containsKey(time.id)).toList()
          ..sort((UsageTime a, UsageTime b) => b.at.compareTo(a.at));
    final List<Recording> played =
        recordings.where((Recording recording) => history.coverPlayedAt(recording.id) != null).toList()
          ..sort((Recording a, Recording b) => history.coverPlayedAt(b.id)!.compareTo(history.coverPlayedAt(a.id)!));
    return RecentActivity(
      songs: <Song>[for (final UsageTime time in opened.take(recentCount)) songsById[time.id]!],
      covers: played.take(recentCount).toList(),
    );
  }
}
