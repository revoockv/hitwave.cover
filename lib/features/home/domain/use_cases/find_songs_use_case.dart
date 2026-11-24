import '../../../song/domain/entities/song.dart';

/// Finds the songs whose name, artist or album contain a query.
final class FindSongsUseCase {
  /// Creates a new [FindSongsUseCase].
  const FindSongsUseCase();

  /// The [songs] that match [query], in their order; all of them when the query is empty.
  List<Song> call({required List<Song> songs, required String query}) {
    final String needle = query.trim().toLowerCase();
    if (needle.isEmpty) return songs;
    return songs.where((Song song) => _matches(song, needle)).toList();
  }

  static bool _matches(Song song, String needle) =>
      song.name.toLowerCase().contains(needle) ||
      song.author.toLowerCase().contains(needle) ||
      (song.album ?? '').toLowerCase().contains(needle);
}
