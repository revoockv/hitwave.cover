import 'sync_conflict.dart';
import 'sync_summary.dart';

/// State of the synchronisation with another device.
sealed class SyncState {
  const SyncState();

  /// Nothing is going on.
  static const SyncState idle = IdleSyncState();
}

/// Nothing is going on.
final class IdleSyncState extends SyncState {
  /// Creates an [IdleSyncState].
  const IdleSyncState();
}

/// This device waits for another one that scans [code] (shown as a QR code).
final class HostingSyncState extends SyncState {
  /// The code to scan or to type on the other device.
  final String code;

  /// Creates a [HostingSyncState].
  const HostingSyncState(this.code);
}

/// Data is being exchanged.
final class SyncingSyncState extends SyncState {
  /// What is being done now.
  final String step;

  /// Done part, 0.0–1.0, or `null` when unknown.
  final double? fraction;

  /// Creates a [SyncingSyncState].
  const SyncingSyncState({required this.step, required this.fraction});
}

/// The devices differ in ways only the user can decide; the exchange waits for the choices.
final class ConflictsSyncState extends SyncState {
  /// What differs.
  final List<SyncConflict> conflicts;

  /// Creates a [ConflictsSyncState].
  const ConflictsSyncState(this.conflicts);
}

/// The synchronisation finished.
final class DoneSyncState extends SyncState {
  /// What it added.
  final SyncSummary summary;

  /// Creates a [DoneSyncState].
  const DoneSyncState(this.summary);
}

/// The synchronisation failed with [message].
final class FailedSyncState extends SyncState {
  /// Why it failed.
  final String message;

  /// Creates a [FailedSyncState].
  const FailedSyncState(this.message);
}
