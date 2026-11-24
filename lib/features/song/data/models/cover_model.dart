import '../../domain/entities/cover.dart';

/// Data transfer object representing a cover from Firestore.
///
/// Maps between Firestore document data and the domain [Cover] entity.
final class CoverModel {
  static const String _idField = 'id';
  static const String _timestampField = 'timestamp';
  static const String _notesField = 'notes';

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

  /// Reads the map Hive returned for a cover of a song; the audio is not stored there.
  factory CoverModel.fromStored(Object? stored) {
    final Map<dynamic, dynamic> map = stored! as Map<dynamic, dynamic>;
    return CoverModel(
      id: map[_idField] as String,
      timestamp: map[_timestampField] as int,
      audioBytes: const <int>[],
      notes: map[_notesField] as String?,
    );
  }

  /// The map Hive stores for this cover inside its song.
  Map<String, dynamic> toMap() => <String, dynamic>{_idField: id, _timestampField: timestamp, _notesField: notes};

  /// This cover under [id], with the time and notes of this one.
  CoverModel withId(String id) => CoverModel(id: id, timestamp: timestamp, audioBytes: audioBytes, notes: notes);
}
