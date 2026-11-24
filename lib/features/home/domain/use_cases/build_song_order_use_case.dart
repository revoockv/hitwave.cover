import '../../../history/domain/entities/usage_history.dart';
import '../../../recordings/domain/entities/cover_counts.dart';
import '../../../song/domain/entities/song.dart';
import '../../../song/domain/entities/song_sort.dart';

/// Puts songs in the chosen order; ties and the artist order go by name.
final class BuildSongOrderUseCase {
  /// Creates a new [BuildSongOrderUseCase].
  const BuildSongOrderUseCase();

  /// [songs] ordered by [sort]: by name, by artist, opened last first ([history]) or most covers first ([coverCounts]).
  List<Song> call({
    required List<Song> songs,
    required SongSort sort,
    required UsageHistory history,
    required CoverCounts coverCounts,
  }) {
    final DateTime never = DateTime.fromMillisecondsSinceEpoch(0);
    final List<Song> ordered = songs.toList();
    switch (sort) {
      case SongSort.name:
        ordered.sort(_byName);
      case SongSort.artists:
        ordered.sort((Song a, Song b) {
          final int byArtist = a.author.toLowerCase().compareTo(b.author.toLowerCase());
          return byArtist != 0 ? byArtist : _byName(a, b);
        });
      case SongSort.recent:
        ordered.sort((Song a, Song b) {
          final int byTime = (history.songOpenedAt(b.id) ?? never).compareTo(history.songOpenedAt(a.id) ?? never);
          return byTime != 0 ? byTime : _byName(a, b);
        });
      case SongSort.covers:
        ordered.sort((Song a, Song b) {
          final int byCovers = coverCounts.of(b.id).compareTo(coverCounts.of(a.id));
          return byCovers != 0 ? byCovers : _byName(a, b);
        });
    }
    return ordered;
  }

  static int _byName(Song a, Song b) => a.name.toLowerCase().compareTo(b.name.toLowerCase());
}
