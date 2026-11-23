/// The song a shared cover belongs to: its file is named and its message written after it.
final class SharedSong {
  /// Artist.
  final String author;

  /// Name of the song.
  final String name;

  /// Creates a [SharedSong].
  const SharedSong({required this.author, required this.name});
}
