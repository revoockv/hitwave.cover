import 'recording_version.dart';

/// What the player is doing.
final class PlaybackState {
  /// Nothing loaded.
  static const PlaybackState stopped = PlaybackState(
    recordingId: null,
    version: RecordingVersion.enhanced,
    isPlaying: false,
    position: Duration.zero,
    duration: Duration.zero,
  );

  /// The recording that is loaded, or `null` when stopped.
  final String? recordingId;

  /// Which file of it is loaded.
  final RecordingVersion version;

  /// Whether it is playing now (`false` while paused).
  final bool isPlaying;

  /// Position in the played part.
  final Duration position;

  /// Length of the played part.
  final Duration duration;

  /// Creates a [PlaybackState].
  const PlaybackState({
    required this.recordingId,
    required this.version,
    required this.isPlaying,
    required this.position,
    required this.duration,
  });
}
