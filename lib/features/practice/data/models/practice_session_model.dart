import '../../domain/entities/practice_session.dart';

/// A practice session as stored in Hive.
final class PracticeSessionModel {
  static const String _idField = 'id';
  static const String _songIdField = 'songId';
  static const String _startedAtField = 'startedAt';
  static const String _secondsField = 'seconds';

  /// Unique id.
  final String id;

  /// Id of the song.
  final String songId;

  /// When the session started.
  final DateTime startedAt;

  /// Length in whole seconds.
  final int seconds;

  /// Creates a [PracticeSessionModel].
  const PracticeSessionModel({required this.id, required this.songId, required this.startedAt, required this.seconds});

  /// Reads what Hive returned for one record.
  factory PracticeSessionModel.fromStored(Object? value) => PracticeSessionModel.fromMap(value! as Map<dynamic, dynamic>);

  /// Reads a stored map.
  factory PracticeSessionModel.fromMap(Map<dynamic, dynamic> map) => PracticeSessionModel(
    id: map[_idField] as String,
    songId: map[_songIdField] as String,
    startedAt: DateTime.parse(map[_startedAtField] as String),
    seconds: map[_secondsField] as int,
  );

  /// The model of [session].
  factory PracticeSessionModel.fromEntity(PracticeSession session) => PracticeSessionModel(
    id: session.id,
    songId: session.songId,
    startedAt: session.startedAt,
    seconds: session.duration.inSeconds,
  );

  /// The map to store.
  Map<String, dynamic> toMap() => <String, dynamic>{
    _idField: id,
    _songIdField: songId,
    _startedAtField: startedAt.toUtc().toIso8601String(),
    _secondsField: seconds,
  };

  /// The domain entity.
  PracticeSession toEntity() => PracticeSession(
    id: id,
    songId: songId,
    startedAt: startedAt.toLocal(),
    duration: Duration(seconds: seconds),
  );

  /// A copy that belongs to [songId].
  PracticeSessionModel withSongId(String songId) =>
      PracticeSessionModel(id: id, songId: songId, startedAt: startedAt, seconds: seconds);
}
