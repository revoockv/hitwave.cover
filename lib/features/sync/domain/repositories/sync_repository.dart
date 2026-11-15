import 'package:flutter/foundation.dart' show ValueListenable;

import '../../../../core/domain/entities/result.dart';
import '../entities/sync_state.dart';
import '../entities/sync_failure.dart';

/// Synchronises the songs, covers, practice and history with another device on the same network.
///
/// One device hosts (shows a QR code with its address and a one-time key), the other scans it
/// and both get what they miss. Songs are matched by artist and name, covers and practice
/// sessions by their ids. Each device remembers what was deleted on it; a song or cover deleted
/// on one device and still on the other, or a song that differs, is a conflict the user of the
/// scanning device decides about before anything changes.
abstract interface class SyncRepository {
  /// The state of the synchronisation.
  ValueListenable<SyncState> watchSyncState();

  /// Whether this platform can synchronise (not the web).
  bool isSupported();

  /// Starts waiting for another device; the state gets the code to show.
  Future<Result<void, SyncFailure>> startHosting();

  /// Synchronises with the device that shows [code]. When anything would change, the state turns
  /// to [ReviewSyncState] and the exchange waits for [applyChanges].
  Future<Result<void, SyncFailure>> syncWith(String code);

  /// Goes on with the exchange that waits, making the changes whose ids are in [chosen].
  Future<Result<void, SyncFailure>> applyChanges(Set<String> chosen);

  /// Stops waiting or forgets the result; back to idle.
  Future<Result<void, SyncFailure>> stopSync();
}
