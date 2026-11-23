import 'package:flutter/foundation.dart' show ValueListenable;

import '../repositories/backup_repository.dart';

/// Use case that exposes the current backup status as a [ValueListenable].
///
/// Allows the UI to reactively watch the backup status string (idle,
/// exporting, importing, success, or error message).
final class WatchBackupStatusUseCase {
  final BackupRepository _repository;

  /// Creates a new [WatchBackupStatusUseCase].
  WatchBackupStatusUseCase(this._repository);

  /// Returns the backup status [ValueListenable].
  ///
  /// Emits a [String] describing the current backup operation state.
  ValueListenable<String> call() {
    return _repository.watchStatus();
  }
}
