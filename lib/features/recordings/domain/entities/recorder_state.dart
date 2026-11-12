/// State of the microphone recorder.
sealed class RecorderState {
  const RecorderState();

  /// Nothing is being recorded.
  static const RecorderState idle = IdleRecorderState();
}

/// Nothing is being recorded.
final class IdleRecorderState extends RecorderState {
  /// Creates an [IdleRecorderState].
  const IdleRecorderState();
}

/// A take of [songId] is being recorded.
final class RecordingRecorderState extends RecorderState {
  /// The song being recorded.
  final String songId;

  /// Time since recording started.
  final Duration elapsed;

  /// Input level, 0.0 (silence) – 1.0 (full scale).
  final double level;

  /// Creates a [RecordingRecorderState].
  const RecordingRecorderState({required this.songId, required this.elapsed, required this.level});
}
