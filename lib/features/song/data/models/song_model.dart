import '../../domain/entities/cover.dart';
import '../../domain/entities/song.dart';

/// Data transfer object representing a song from Firestore.
///
/// Maps between Firestore document data and the domain [Song] entity.
final class SongModel {
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

  /// The list of cover IDs associated with this song.
  final List<String> coverIds;

  /// Saved auto-scroll speed of the lyrics, or `null` when never set.
  final double? scrollSpeed;

  /// Saved space above the lyrics before they scroll, or `null` when never set.
  final double? leadIn;

  /// [scrollSpeed] on a big screen, or `null` when never set there.
  final double? wideScrollSpeed;

  /// [leadIn] on a big screen, or `null` when never set there.
  final double? wideLeadIn;

  /// Creates a new [SongModel] instance.
  const SongModel({
    required this.id,
    required this.author,
    required this.name,
    this.album,
    required this.lyrics,
    required this.coverIds,
    this.scrollSpeed,
    this.leadIn,
    this.wideScrollSpeed,
    this.wideLeadIn,
  });

  /// Converts this model to a domain [Song] entity.
  Song toEntity({required List<Cover> covers}) {
    return Song(
      id: id,
      author: author,
      name: name,
      album: album,
      lyrics: lyrics,
      covers: covers,
      scrollSpeed: scrollSpeed,
      leadIn: leadIn,
      wideScrollSpeed: wideScrollSpeed,
      wideLeadIn: wideLeadIn,
    );
  }

  /// Creates a [SongModel] from a domain [Song] entity.
  static SongModel fromEntity(Song entity) {
    return SongModel(
      id: entity.id,
      author: entity.author,
      name: entity.name,
      album: entity.album,
      lyrics: entity.lyrics,
      coverIds: (entity.covers.isNotEmpty) ? entity.covers.map((cover) => cover.id).toList() : [],
      scrollSpeed: entity.scrollSpeed,
      leadIn: entity.leadIn,
      wideScrollSpeed: entity.wideScrollSpeed,
      wideLeadIn: entity.wideLeadIn,
    );
  }
}
