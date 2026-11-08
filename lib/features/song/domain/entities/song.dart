import 'cover.dart';

/// Represents a song in the application.
///
/// Contains the core song metadata and a list of associated covers.
final class Song {
  /// The unique identifier for the song.
  final String id;

  /// The author/artist name for this song.
  final String author;

  /// The name/title of the song.
  final String name;

  /// The album name, if this song belongs to one.
  final String? album;

  /// The lyrics content for this song.
  final String lyrics;

  /// The list of covers associated with this song.
  final List<Cover> covers;

  /// Saved auto-scroll speed of the lyrics (0.0–1.0), or `null` when never set.
  final double? scrollSpeed;

  /// Creates a new [Song] instance.
  const Song({
    required this.id,
    required this.author,
    required this.name,
    this.album,
    required this.lyrics,
    required this.covers,
    this.scrollSpeed,
  });
}
