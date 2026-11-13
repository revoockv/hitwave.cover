/// The step of the vocal chain that has just started.
final class EnhanceProgress {
  /// 1-based number of the step.
  final int step;

  /// Number of steps.
  final int steps;

  /// What the step does, in English (from the engine).
  final String label;

  /// Part of the work done before this step, 0.0–1.0.
  final double fraction;

  /// Creates an [EnhanceProgress].
  const EnhanceProgress({required this.step, required this.steps, required this.label, required this.fraction});
}
