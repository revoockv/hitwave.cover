import '../../../../core/presentation/l10n/app_translations.dart';
import '../../domain/entities/backup_failure.dart';
import '../../domain/entities/import_conflict.dart';
import '../widgets/import_conflict_dialog_widget.dart';

/// The text of a [BackupFailure] shown to the user.
extension BackupFailureText on BackupFailure {
  /// The text of this failure in the language of [t].
  String text(Translations t) => switch (this) {
    BackupFailure.exportSongs => t.backup.failure.exportSongs,
    BackupFailure.importSongs => t.backup.failure.importSongs,
    BackupFailure.shareBackup => t.backup.failure.shareBackup,
  };
}

/// The texts of the backup widgets in the language of these [Translations].
extension BackupWidgetTexts on Translations {
  static const String _songSeparator = ' — ';

  /// The texts of the dialog about [conflict], with [othersCount] songs already here after it.
  ImportConflictTexts importConflict(ImportConflict conflict, int othersCount) => ImportConflictTexts(
    titleText: backup.conflictTitle,
    messageText: backup.conflictMessage(song: '${conflict.author}$_songSeparator${conflict.name}'),
    lyricsText: conflict.hasSameLyrics ? backup.sameLyrics : backup.otherLyrics,
    forOthersLabel: backup.forOthers(n: othersCount),
    replaceLabel: backup.replace,
    replaceHint: backup.replaceHint,
    keepBothLabel: backup.keepBoth,
    keepBothHint: backup.keepBothHint,
    skipLabel: backup.skip,
    skipHint: backup.skipHint,
    cancelLabel: backup.cancelImport,
  );
}
