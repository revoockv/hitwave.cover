import '../../../recordings/domain/entities/recording.dart';
import '../../../song/domain/entities/song.dart';

/// What the home tab shows as recent: the songs opened last and the covers played last, newest first.
final class RecentActivity {
  /// The songs opened last that still exist.
  final List<Song> songs;

  /// The covers played last that still exist.
  final List<Recording> covers;

  /// Creates the recent activity.
  const RecentActivity({required this.songs, required this.covers});
}
