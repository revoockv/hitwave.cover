import 'recording_status.dart';

/// One recorded take of a song, kept only on this device.
///
/// The raw take is always kept whole; the enhanced file is made from it automatically.
final class Recording {
  /// Unique id of the recording.
  final String id;

  /// Id of the song it belongs to.
  final String songId;

  /// When recording started.
  final DateTime recordedAt;

  /// Length of the raw take in seconds.
  final double durationSeconds;

  /// The raw WAV file as the microphone recorded it.
  final String rawPath;

  /// The enhanced WAV file; `null` until the enhancement succeeded.
  final String? enhancedPath;

  /// Where the enhanced file starts in the raw take, in seconds (silence trimmed before it).
  final double keptFromSeconds;

  /// Where the enhanced file ends in the raw take, in seconds; `null` = the end of the take.
  final double? keptToSeconds;

  /// State of the enhancement.
  final RecordingStatus status;

  /// Why the enhancement failed, when [status] is [RecordingStatus.enhanceFailed].
  final String? enhanceError;

  /// Whether the microphone gave no sound during the whole take (a wrong input chosen).
  final bool isSilent;

  /// Creates a [Recording].
  const Recording({
    required this.id,
    required this.songId,
    required this.recordedAt,
    required this.durationSeconds,
    required this.rawPath,
    required this.enhancedPath,
    required this.keptFromSeconds,
    required this.keptToSeconds,
    required this.status,
    required this.enhanceError,
    this.isSilent = false,
  });
}
