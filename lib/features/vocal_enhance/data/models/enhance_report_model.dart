import '../../domain/entities/enhance_report.dart';
import 'recording_analysis_model.dart';
import '../../domain/entities/enhance_setting.dart';

/// The `report` object of the engine's `done` event.
final class EnhanceReportModel {
  static const String _inputKey = 'input';
  static const String _outputKey = 'output';
  static const String _settingsKey = 'settings';
  static const String _beforeKey = 'before';
  static const String _afterKey = 'after';
  static const String _secondsKey = 'seconds';
  static const String _keptFromKey = 'kept_from_s';
  static const String _keptToKey = 'kept_to_s';

  /// The raw recording.
  final String inputPath;

  /// The enhanced WAV file.
  final String outputPath;

  /// Every applied setting.
  final Map<String, double> settings;

  /// Levels before.
  final RecordingAnalysisModel before;

  /// Levels after.
  final RecordingAnalysisModel after;

  /// Processing time in seconds.
  final double secondsSpent;

  /// Start of the kept part of the raw take, in seconds.
  final double keptFromSeconds;

  /// End of the kept part of the raw take, in seconds; `null` = the end.
  final double? keptToSeconds;

  /// Creates an [EnhanceReportModel].
  const EnhanceReportModel({
    required this.inputPath,
    required this.outputPath,
    required this.settings,
    required this.before,
    required this.after,
    required this.secondsSpent,
    this.keptFromSeconds = 0,
    this.keptToSeconds,
  });

  /// Reads the `report` object.
  factory EnhanceReportModel.fromJson(Map<String, dynamic> json) {
    final Map<String, dynamic> settings = json[_settingsKey] as Map<String, dynamic>;
    return EnhanceReportModel(
      inputPath: json[_inputKey] as String,
      outputPath: json[_outputKey] as String,
      settings: settings.map(_toDoubleEntry),
      before: RecordingAnalysisModel.fromJson(json[_beforeKey] as Map<String, dynamic>),
      after: RecordingAnalysisModel.fromJson(json[_afterKey] as Map<String, dynamic>),
      secondsSpent: (json[_secondsKey] as num).toDouble(),
      keptFromSeconds: (json[_keptFromKey] as num?)?.toDouble() ?? 0,
      keptToSeconds: (json[_keptToKey] as num?)?.toDouble(),
    );
  }

  /// Creates a model from a domain [entity].
  factory EnhanceReportModel.fromEntity(EnhanceReport entity) {
    return EnhanceReportModel(
      inputPath: entity.inputPath,
      outputPath: entity.outputPath,
      settings: <String, double>{for (final EnhanceSetting setting in entity.settings) setting.name: setting.value},
      before: RecordingAnalysisModel.fromEntity(entity.before),
      after: RecordingAnalysisModel.fromEntity(entity.after),
      secondsSpent: entity.secondsSpent,
      keptFromSeconds: entity.keptFromSeconds,
      keptToSeconds: entity.keptToSeconds,
    );
  }

  /// Converts the model into a domain entity.
  EnhanceReport toEntity() {
    return EnhanceReport(
      inputPath: inputPath,
      outputPath: outputPath,
      settings: <EnhanceSetting>[
        for (final MapEntry<String, double> entry in settings.entries) EnhanceSetting(entry.key, entry.value),
      ],
      before: before.toEntity(),
      after: after.toEntity(),
      secondsSpent: secondsSpent,
      keptFromSeconds: keptFromSeconds,
      keptToSeconds: keptToSeconds,
    );
  }

  static MapEntry<String, double> _toDoubleEntry(String key, dynamic value) =>
      MapEntry<String, double>(key, (value as num).toDouble());
}
