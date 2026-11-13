import '../../domain/entities/sync_step.dart';

/// A sync step as the devices send it to each other: `downloading:3:10` or `merging`.
final class SyncStepModel {
  static const String _separator = ':';
  static const int _withCounts = 3;

  /// The step.
  final SyncStep step;

  /// How many files are done.
  final int? done;

  /// How many files the step moves.
  final int? total;

  /// Creates a [SyncStepModel].
  const SyncStepModel(this.step, {this.done, this.total});

  /// Reads [text]; `null` for a step this app does not know (another app version).
  static SyncStepModel? decode(String text) {
    final List<String> parts = text.split(_separator);
    final SyncStep? step = SyncStep.values.asNameMap()[parts.first];
    if (step == null) return null;
    if (parts.length != _withCounts) return SyncStepModel(step);
    return SyncStepModel(step, done: int.tryParse(parts[1]), total: int.tryParse(parts[2]));
  }

  /// The text to send.
  String encode() =>
      done == null || total == null ? step.name : <String>[step.name, '$done', '$total'].join(_separator);
}
