import 'recording_analysis.dart';

/// Result of enhancing one recording.
final class EnhanceReport {
  /// The raw recording.
  final String inputPath;

  /// The enhanced 24-bit WAV file.
  final String outputPath;

  /// Every setting of the chain as it was applied.
  final Map<String, double> settings;

  /// Levels of the raw recording.
  final RecordingAnalysis before;

  /// Levels of the enhanced recording.
  final RecordingAnalysis after;

  /// How long the processing took, in seconds.
  final double secondsSpent;

  /// Where the enhanced file starts in the raw take, in seconds (silence trimmed before it).
  final double keptFromSeconds;

  /// Where the enhanced file ends in the raw take, in seconds; `null` = the end of the take.
  final double? keptToSeconds;

  /// Creates an [EnhanceReport].
  const EnhanceReport({
    required this.inputPath,
    required this.outputPath,
    required this.settings,
    required this.before,
    required this.after,
    required this.secondsSpent,
    this.keptFromSeconds = 0,
    this.keptToSeconds,
  });
}
