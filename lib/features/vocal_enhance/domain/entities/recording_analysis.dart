/// Levels of one recording and the problems they reveal.
///
/// A level is `null` when it cannot be measured (silence).
final class RecordingAnalysis {
  /// Length of the recording in seconds.
  final double durationSeconds;

  /// Samples per second.
  final int sampleRate;

  /// Number of channels.
  final int channels;

  /// Integrated loudness (ITU-R BS.1770) in LUFS.
  final double? integratedLufs;

  /// Highest inter-sample peak in dBTP.
  final double? truePeakDb;

  /// Share of the samples at full scale, in percent.
  final double clippedPercent;

  /// Level of the quietest parts in dBFS.
  final double? noiseFloorDb;

  /// Loud parts above the noise floor, in dB.
  final double? signalToNoiseDb;

  /// Whether the input level was too high and the peaks were cut off.
  final bool isClipped;

  /// Whether the input level was so low that the noise is raised with the voice.
  final bool isTooQuiet;

  /// Whether the room noise is close to the voice.
  final bool isNoisy;

  /// Creates a [RecordingAnalysis].
  const RecordingAnalysis({
    required this.durationSeconds,
    required this.sampleRate,
    required this.channels,
    required this.integratedLufs,
    required this.truePeakDb,
    required this.clippedPercent,
    required this.noiseFloorDb,
    required this.signalToNoiseDb,
    required this.isClipped,
    required this.isTooQuiet,
    required this.isNoisy,
  });
}
