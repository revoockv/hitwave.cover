/// A song of a backup that is already in the library (same author and name, case ignored).
final class ImportConflict {
  /// Position of the song in the backup.
  final int index;

  /// Author of the song.
  final String author;

  /// Name of the song.
  final String name;

  /// Whether the lyrics in the backup are the same as in the library.
  final bool hasSameLyrics;

  /// Creates an [ImportConflict].
  const ImportConflict({required this.index, required this.author, required this.name, required this.hasSameLyrics});
}
