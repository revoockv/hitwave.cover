import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:watch_it/watch_it.dart';

import '../../../../core/domain/entities/result.dart';
import '../../../../core/presentation/l10n/app_translations.dart';
import '../../../../core/presentation/theme.dart';
import '../../../backup/domain/entities/backup_failure.dart';
import '../../../backup/presentation/di/backup_getters.dart';
import '../../../backup/presentation/l10n/backup_texts.dart';
import '../../../backup/presentation/widgets/backup_options_dialog_widget.dart';
import '../../../history/domain/entities/history_failure.dart';
import '../../../history/presentation/di/history_getters.dart';
import '../../../history/presentation/l10n/history_texts.dart';
import '../../../practice/domain/entities/practice_failure.dart';
import '../../../practice/presentation/di/practice_getters.dart';
import '../../../practice/presentation/l10n/practice_texts.dart';
import '../../../recordings/domain/entities/recordings_failure.dart';
import '../../../recordings/presentation/di/recordings_getters.dart';
import '../../../recordings/presentation/l10n/recordings_texts.dart';
import '../../../song/domain/entities/song_failure.dart';
import '../../../song/presentation/di/song_getters.dart';
import '../../../song/presentation/l10n/song_texts.dart';
import '../../../sync/presentation/di/sync_getters.dart';
import '../../../sync/presentation/pages/sync_page.dart';
import '../../domain/entities/accent_color.dart';
import '../../domain/entities/app_language.dart';
import '../../domain/entities/app_settings.dart';
import '../../domain/entities/app_theme_style.dart';
import '../../domain/entities/settings_failure.dart';
import '../controllers/clear_data_controller.dart';
import '../di/settings_getters.dart';
import '../l10n/settings_texts.dart';
import '../widgets/accent_color_picker_widget.dart';
import '../widgets/clear_data_dialog_widget.dart';
import '../widgets/language_picker_widget.dart';
import '../widgets/theme_picker_widget.dart';

/// The app settings: the look, the main color and the language of the app, the data (backup,
/// sync, clearing).
final class SettingsPage extends WatchingWidget {
  /// Backup status while songs are exported.
  static const String _backupStatusExporting = 'exporting';

  /// Backup status while songs are imported.
  static const String _backupStatusImporting = 'importing';

  /// Height of the backup progress line under the app bar.
  static const double _progressHeight = 2;

  /// Creates the page.
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final AppSettings settings = watch(watchSettingsUseCase()).value;
    final String backupStatus = watch(watchBackupStatusUseCase()).value;
    final bool isBackupRunning = backupStatus == _backupStatusExporting || backupStatus == _backupStatusImporting;
    final Translations t = context.t;
    final ThemeData theme = Theme.of(context);
    final TextStyle? sectionStyle = theme.textTheme.titleSmall;

    return Scaffold(
      appBar: AppBar(
        title: Text(t.settings.title),
        bottom: isBackupRunning
            ? const PreferredSize(
                preferredSize: Size.fromHeight(_progressHeight),
                child: LinearProgressIndicator(minHeight: _progressHeight),
              )
            : null,
      ),
      body: ListView(
        padding: const EdgeInsets.only(bottom: AppTheme.spacingLarge),
        children: <Widget>[
          ListTile(title: Text(t.settings.theme, style: sectionStyle)),
          ThemePickerWidget(
            selected: settings.themeStyle,
            onSelected: (AppThemeStyle style) => _onThemeStyleSelected(context, style),
          ),
          ListTile(title: Text(t.settings.accentColor, style: sectionStyle)),
          AccentColorPickerWidget(
            selected: settings.accentColor,
            onSelected: (AccentColor color) => _onAccentColorSelected(context, color),
          ),
          const SizedBox(height: AppTheme.spacingMedium),
          ListTile(title: Text(t.settings.language, style: sectionStyle)),
          LanguagePickerWidget(
            selected: settings.language,
            onSelected: (AppLanguage language) => _onLanguageSelected(context, language),
          ),
          ListTile(title: Text(t.settings.data, style: sectionStyle)),
          ListTile(
            leading: const Icon(Icons.file_upload_outlined),
            title: Text(t.song.importSongs),
            enabled: !isBackupRunning,
            onTap: () => _onImportPressed(context),
          ),
          ListTile(
            leading: const Icon(Icons.file_download_outlined),
            title: Text(t.song.exportSongs),
            enabled: !isBackupRunning,
            onTap: () => _onExportPressed(context),
          ),
          if (isSyncSupportedUseCase())
            ListTile(leading: const Icon(Icons.sync), title: Text(t.song.sync), onTap: () => _onSyncPressed(context)),
          ListTile(
            leading: Icon(Icons.delete_sweep_outlined, color: theme.colorScheme.error),
            title: Text(t.settings.clearData, style: TextStyle(color: theme.colorScheme.error)),
            enabled: !isBackupRunning,
            onTap: () => _onClearDataPressed(context),
          ),
        ],
      ),
    );
  }

  Future<void> _onLanguageSelected(BuildContext context, AppLanguage language) =>
      _showSettingsFailure(context, setLanguageUseCase(language));

  Future<void> _onThemeStyleSelected(BuildContext context, AppThemeStyle style) =>
      _showSettingsFailure(context, setThemeStyleUseCase(style));

  Future<void> _onAccentColorSelected(BuildContext context, AccentColor color) =>
      _showSettingsFailure(context, setAccentColorUseCase(color));

  Future<void> _onExportPressed(BuildContext context) async {
    final Translations t = context.t;
    final bool? includeRecordings = await _askIncludeRecordings(context, t.song.exportSongs, t.song.exportQuestion);
    if (includeRecordings == null) return;
    final Result<void, BackupFailure> result = await exportSongsUseCase(
      includeRecordings: includeRecordings,
      pickerTitle: t.backup.exportDialogTitle,
    );
    if (!context.mounted) return;
    _showMessage(
      ScaffoldMessenger.of(context),
      result.when(success: (void _) => t.song.exportDone, failure: (BackupFailure failure) => failure.text(t)),
    );
  }

  Future<void> _onImportPressed(BuildContext context) async {
    final Translations t = context.t;
    final bool? includeRecordings = await _askIncludeRecordings(context, t.song.importSongs, t.song.importQuestion);
    if (includeRecordings == null) return;
    final Result<void, BackupFailure> result = await importSongsUseCase(includeRecordings: includeRecordings);
    if (!context.mounted) return;
    _showMessage(
      ScaffoldMessenger.of(context),
      result.when(success: (void _) => t.song.importDone, failure: (BackupFailure failure) => failure.text(t)),
    );
  }

  /// Asks whether the recordings go too; `null` when cancelled. The web keeps no recordings.
  Future<bool?> _askIncludeRecordings(BuildContext context, String title, String message) async {
    if (kIsWeb) return false;
    return showDialog<bool>(
      context: context,
      builder: (BuildContext context) => BackupOptionsDialogWidget(title: title, message: message, confirmLabel: title),
    );
  }

  void _onSyncPressed(BuildContext context) {
    Navigator.of(context).push(MaterialPageRoute<void>(builder: (BuildContext context) => const SyncPage()));
  }

  /// Asks what to clear, then clears it; the first failure stops and is shown.
  Future<void> _onClearDataPressed(BuildContext context) async {
    final Translations t = context.t;
    final Set<ClearableData>? chosen = await showDialog<Set<ClearableData>>(
      context: context,
      builder: (BuildContext context) => const ClearDataDialogWidget(),
    );
    if (chosen == null || chosen.isEmpty) return;
    final String? failure = await _clear(t, chosen);
    if (!context.mounted) return;
    _showMessage(ScaffoldMessenger.of(context), failure ?? t.settings.cleared);
  }

  /// Clears [chosen]; the text of the first failure, or `null` when everything was cleared.
  static Future<String?> _clear(Translations t, Set<ClearableData> chosen) async {
    if (chosen.contains(ClearableData.songs)) {
      final Result<void, SongFailure> songs = await deleteAllSongsUseCase();
      if (songs case FailureResult<void, SongFailure>(:final SongFailure failure)) return failure.text(t);
    }
    if (chosen.contains(ClearableData.covers)) {
      final Result<void, RecordingsFailure> covers = await deleteAllRecordingsUseCase();
      if (covers case FailureResult<void, RecordingsFailure>(:final RecordingsFailure failure)) return failure.text(t);
    }
    if (chosen.contains(ClearableData.practice)) {
      final Result<void, PracticeFailure> practice = await clearPracticeUseCase();
      if (practice case FailureResult<void, PracticeFailure>(:final PracticeFailure failure)) return failure.text(t);
    }
    if (chosen.contains(ClearableData.history)) {
      final Result<void, HistoryFailure> history = await clearHistoryUseCase();
      if (history case FailureResult<void, HistoryFailure>(:final HistoryFailure failure)) return failure.text(t);
    }
    return null;
  }

  /// Waits for [saving] and shows its failure, if any.
  static Future<void> _showSettingsFailure(BuildContext context, Future<Result<void, SettingsFailure>> saving) async {
    final Translations t = context.t;
    final Result<void, SettingsFailure> result = await saving;
    if (!context.mounted) return;
    if (result case FailureResult<void, SettingsFailure>(:final SettingsFailure failure)) {
      _showMessage(ScaffoldMessenger.of(context), failure.text(t));
    }
  }

  static void _showMessage(ScaffoldMessengerState messenger, String message) {
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }
}
