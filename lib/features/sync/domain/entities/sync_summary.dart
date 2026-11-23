/// What one synchronisation added on each side.
final class SyncSummary {
  /// Songs added on this device.
  final int songsReceived;

  /// Covers added on this device.
  final int coversReceived;

  /// Practice sessions added on this device.
  final int sessionsReceived;

  /// Songs added on the other device.
  final int songsSent;

  /// Covers added on the other device.
  final int coversSent;

  /// Practice sessions added on the other device.
  final int sessionsSent;

  /// Songs and covers deleted on this device.
  final int deletedHere;

  /// Songs and covers deleted on the other device.
  final int deletedThere;

  /// Songs updated on this device.
  final int updatedHere;

  /// Songs updated on the other device.
  final int updatedThere;

  /// Creates a [SyncSummary].
  const SyncSummary({
    required this.songsReceived,
    required this.coversReceived,
    required this.sessionsReceived,
    required this.songsSent,
    required this.coversSent,
    required this.sessionsSent,
    this.deletedHere = 0,
    this.deletedThere = 0,
    this.updatedHere = 0,
    this.updatedThere = 0,
  });
}
