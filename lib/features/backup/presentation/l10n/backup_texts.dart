import '../../../../core/presentation/l10n/app_translations.dart';
import '../../domain/entities/backup_failure.dart';

/// The text of a [BackupFailure] shown to the user.
extension BackupFailureText on BackupFailure {
  /// The text of this failure in the language of [t].
  String text(Translations t) => switch (this) {
    BackupFailure.exportSongs => t.backup.failure.exportSongs,
    BackupFailure.importSongs => t.backup.failure.importSongs,
    BackupFailure.shareBackup => t.backup.failure.shareBackup,
  };
}
