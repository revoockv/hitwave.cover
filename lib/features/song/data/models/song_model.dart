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

  /// Creates a new [SongModel] instance.
  const SongModel({
    required this.id,
    required this.author,
    required this.name,
    this.album,
    required this.lyrics,
    required this.coverIds,
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
      coverIds: entity.covers.map((cover) => cover.id).toList(),
    );
  }
}
