import '../../domain/entities/recording_analysis.dart';

/// Measurements of a recording as the audio engine sends them (JSON, `null` for `-inf`).
final class RecordingAnalysisModel {
  static const String _durationKey = 'duration_s';
  static const String _sampleRateKey = 'sample_rate';
  static const String _channelsKey = 'channels';
  static const String _lufsKey = 'integrated_lufs';
  static const String _truePeakKey = 'true_peak_db';
  static const String _clippedKey = 'clipped_percent';
  static const String _noiseFloorKey = 'noise_floor_db';
  static const String _snrKey = 'signal_to_noise_db';
  static const String _isClippedKey = 'is_clipped';
  static const String _isTooQuietKey = 'is_too_quiet';
  static const String _isNoisyKey = 'is_noisy';

  /// Length in seconds.
  final double durationSeconds;

  /// Samples per second.
  final int sampleRate;

  /// Number of channels.
  final int channels;

  /// Integrated loudness in LUFS.
  final double? integratedLufs;

  /// Highest inter-sample peak in dBTP.
  final double? truePeakDb;

  /// Share of clipped samples in percent.
  final double clippedPercent;

  /// Level of the quietest parts in dBFS.
  final double? noiseFloorDb;

  /// Loud parts above the noise floor in dB.
  final double? signalToNoiseDb;

  /// Whether the peaks were cut off.
  final bool isClipped;

  /// Whether the input level was too low.
  final bool isTooQuiet;

  /// Whether the room noise is close to the voice.
  final bool isNoisy;

  /// Creates a [RecordingAnalysisModel].
  const RecordingAnalysisModel({
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

  /// Reads the `analysis` object of an engine event.
  factory RecordingAnalysisModel.fromJson(Map<String, dynamic> json) {
    return RecordingAnalysisModel(
      durationSeconds: (json[_durationKey] as num).toDouble(),
      sampleRate: (json[_sampleRateKey] as num).toInt(),
      channels: (json[_channelsKey] as num).toInt(),
      integratedLufs: (json[_lufsKey] as num?)?.toDouble(),
      truePeakDb: (json[_truePeakKey] as num?)?.toDouble(),
      clippedPercent: (json[_clippedKey] as num).toDouble(),
      noiseFloorDb: (json[_noiseFloorKey] as num?)?.toDouble(),
      signalToNoiseDb: (json[_snrKey] as num?)?.toDouble(),
      isClipped: json[_isClippedKey] as bool,
      isTooQuiet: json[_isTooQuietKey] as bool,
      isNoisy: json[_isNoisyKey] as bool,
    );
  }

  /// Creates a model from a domain [entity].
  factory RecordingAnalysisModel.fromEntity(RecordingAnalysis entity) {
    return RecordingAnalysisModel(
      durationSeconds: entity.durationSeconds,
      sampleRate: entity.sampleRate,
      channels: entity.channels,
      integratedLufs: entity.integratedLufs,
      truePeakDb: entity.truePeakDb,
      clippedPercent: entity.clippedPercent,
      noiseFloorDb: entity.noiseFloorDb,
      signalToNoiseDb: entity.signalToNoiseDb,
      isClipped: entity.isClipped,
      isTooQuiet: entity.isTooQuiet,
      isNoisy: entity.isNoisy,
    );
  }

  /// Converts the model into a domain entity.
  RecordingAnalysis toEntity() {
    return RecordingAnalysis(
      durationSeconds: durationSeconds,
      sampleRate: sampleRate,
      channels: channels,
      integratedLufs: integratedLufs,
      truePeakDb: truePeakDb,
      clippedPercent: clippedPercent,
      noiseFloorDb: noiseFloorDb,
      signalToNoiseDb: signalToNoiseDb,
      isClipped: isClipped,
      isTooQuiet: isTooQuiet,
      isNoisy: isNoisy,
    );
  }
}
