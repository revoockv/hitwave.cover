import 'sync_conflict.dart';
import 'sync_failure.dart';
import 'sync_step.dart';
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
  /// The step that runs.
  final SyncStep step;

  /// How many of [total] files are done in [SyncStep.downloading] and [SyncStep.uploading].
  final int? done;

  /// How many files the step moves.
  final int? total;

  /// Part of the step done, from 0 to 1, or `null` when unknown.
  final double? fraction;

  /// Whether the other device reports the step.
  final bool isPeer;

  /// Name of the other device when [isPeer]; `null` when it has none.
  final String? peerName;

  /// Creates the state.
  const SyncingSyncState({
    required this.step,
    required this.fraction,
    this.done,
    this.total,
    this.isPeer = false,
    this.peerName,
  });
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
  /// What went wrong.
  final SyncFailure failure;

  /// Name of the other device when it stopped the sync ([SyncFailure.peerStopped]); `null` when it has none.
  final String? peerName;

  /// Why the other device stopped, when it said so.
  final SyncFailure? peerFailure;

  /// Creates the state.
  const FailedSyncState(this.failure, {this.peerName, this.peerFailure});
}
