import '../../domain/entities/cover.dart';

/// Data transfer object representing a cover from Firestore.
///
/// Maps between Firestore document data and the domain [Cover] entity.
final class CoverModel {
  /// The unique identifier for the cover.
  final String id;

  /// The timestamp when this cover was recorded.
  final int timestamp;

  /// The audio data as a list of bytes.
  final List<int> audioBytes;

  /// Optional notes about this cover recording.
  final String? notes;

  /// Creates a new [CoverModel] instance.
  const CoverModel({required this.id, required this.timestamp, required this.audioBytes, this.notes});

  /// Converts this model to a domain [Cover] entity.
  Cover toEntity() {
    return Cover(id: id, date: DateTime.fromMillisecondsSinceEpoch(timestamp), audioBytes: audioBytes, notes: notes);
  }

  /// Creates a [CoverModel] from a domain [Cover] entity.
  static CoverModel fromEntity(Cover entity) {
    return CoverModel(
      id: entity.id,
      timestamp: entity.date.millisecondsSinceEpoch,
      audioBytes: entity.audioBytes,
      notes: entity.notes,
    );
  }
}
