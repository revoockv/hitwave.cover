/// One stretch of practice of a song: from pressing start until both the scrolling and the
/// recording stopped. Kept only on this device.
final class PracticeSession {
  /// Unique id of the session.
  final String id;

  /// Id of the song that was practised.
  final String songId;

  /// When the session started.
  final DateTime startedAt;

  /// How long it lasted.
  final Duration duration;

  /// Creates a [PracticeSession].
  const PracticeSession({required this.id, required this.songId, required this.startedAt, required this.duration});
}
