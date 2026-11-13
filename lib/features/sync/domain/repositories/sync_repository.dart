import 'package:flutter/foundation.dart' show ValueListenable;

import '../../../../core/domain/entities/result.dart';
import '../entities/sync_state.dart';

/// Synchronises the songs, covers, practice and history with another device on the same network.
///
/// One device hosts (shows a QR code with its address and a one-time key), the other scans it
/// and both get what they miss. Nothing is deleted; songs are matched by artist and name, covers
/// and practice sessions by their ids.
abstract interface class SyncRepository {
  /// The state of the synchronisation.
  ValueListenable<SyncState> watchSyncState();

  /// Whether this platform can synchronise (not the web).
  bool isSupported();

  /// Starts waiting for another device; the state gets the code to show.
  Future<Result<void>> startHosting();

  /// Synchronises with the device that shows [code].
  Future<Result<void>> syncWith(String code);

  /// Stops waiting or forgets the result; back to idle.
  Future<Result<void>> stopSync();
}
