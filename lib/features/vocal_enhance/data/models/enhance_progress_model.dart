import '../../domain/entities/enhance_progress.dart';

/// The engine's `progress` event.
final class EnhanceProgressModel {
  static const String _stepKey = 'step';
  static const String _stepsKey = 'steps';
  static const String _labelKey = 'label';
  static const String _fractionKey = 'fraction';

  /// 1-based number of the step.
  final int step;

  /// Number of steps.
  final int steps;

  /// What the step does.
  final String label;

  /// Part of the work done, 0.0–1.0.
  final double fraction;

  /// Creates an [EnhanceProgressModel].
  const EnhanceProgressModel({required this.step, required this.steps, required this.label, required this.fraction});

  /// Reads a `progress` event.
  factory EnhanceProgressModel.fromJson(Map<String, dynamic> json) {
    return EnhanceProgressModel(
      step: (json[_stepKey] as num).toInt(),
      steps: (json[_stepsKey] as num).toInt(),
      label: json[_labelKey] as String,
      fraction: (json[_fractionKey] as num).toDouble(),
    );
  }

  /// Creates a model from a domain [entity].
  factory EnhanceProgressModel.fromEntity(EnhanceProgress entity) {
    return EnhanceProgressModel(step: entity.step, steps: entity.steps, label: entity.label, fraction: entity.fraction);
  }

  /// Converts the model into a domain entity.
  EnhanceProgress toEntity() => EnhanceProgress(step: step, steps: steps, label: label, fraction: fraction);
}
