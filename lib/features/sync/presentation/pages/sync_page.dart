import 'package:flutter/foundation.dart' show defaultTargetPlatform, kIsWeb, TargetPlatform;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:watch_it/watch_it.dart';

import '../../../../core/domain/entities/result.dart';
import '../../../../core/presentation/theme.dart';
import '../../domain/entities/sync_state.dart';
import '../controllers/sync_page_controller.dart';
import '../di/sync_getters.dart';
import '../../domain/entities/sync_conflict.dart';
import '../widgets/sync_conflicts_widget.dart';
import '../widgets/sync_qr_widget.dart';
import '../widgets/sync_summary_widget.dart';
import 'sync_scanner_page.dart';

/// Synchronises the songs, covers, practice and history with another device on the same Wi‑Fi:
/// one device shows a QR code, the other scans it (or takes the code typed by hand).
final class SyncPage extends WatchingWidget {
  static const String _title = 'Синхронізація';
  static const String _intro =
      'Перенесіть пісні, кавери, тренування й історію між пристроями. Нічого не видаляється: кожен пристрій отримує те, чого йому бракує.';
  static const String _showQrLabel = 'Показати QR-код';
  static const String _scanLabel = 'Сканувати QR-код';
  static const String _orLabel = 'або вставте код з іншого пристрою';
  static const String _codeHint = 'hitwave-sync:…';
  static const String _connectLabel = 'Підключитися';
  static const String _doneLabel = 'Готово';
  static const String _copiedMessage = 'Код скопійовано';
  static const double _iconSize = 64;

  /// Creates a new [SyncPage].
  const SyncPage({super.key});

  @override
  Widget build(BuildContext context) {
    final SyncPageController syncPageController = createOnce(
      _createSyncPageController,
      dispose: _disposeSyncPageController,
    );
    final SyncState state = watch(watchSyncStateUseCase()).value;
    final Map<String, SyncChoice> choices = watch(syncPageController.choicesController).value;
    registerHandler(
      target: watchSyncStateUseCase(),
      handler: (BuildContext context, SyncState state, void Function() cancel) =>
          _onStateChanged(syncPageController, state),
    );
    final ThemeData theme = Theme.of(context);

    return PopScope(
      onPopInvokedWithResult: _onPopped,
      child: Scaffold(
        appBar: AppBar(title: const Text(_title)),
        body: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppTheme.spacingLarge),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: AppTheme.maxContentWidth),
              child: switch (state) {
                HostingSyncState(:final String code) => SyncQrWidget(
                  code: code,
                  onCopyPressed: () => _copy(ScaffoldMessenger.of(context), code),
                  onCancelPressed: stopSyncUseCase.call,
                ),
                SyncingSyncState(:final String step, :final double? fraction) => Column(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    LinearProgressIndicator(value: fraction),
                    const SizedBox(height: AppTheme.spacingMedium),
                    Text(step, textAlign: TextAlign.center, style: theme.textTheme.bodyLarge),
                  ],
                ),
                ConflictsSyncState(:final List<SyncConflict> conflicts) => SyncConflictsWidget(
                  conflicts: conflicts,
                  choices: choices,
                  onChoiceChanged: syncPageController.choose,
                  onAllDeletionsChosen: (SyncChoice choice) => syncPageController.chooseForAll(conflicts, choice),
                  onAllChangesChosen: (SyncChoice choice) => syncPageController.chooseForAll(conflicts, choice),
                  onContinuePressed: () => _resolve(syncPageController),
                  onCancelPressed: stopSyncUseCase.call,
                ),
                DoneSyncState(:final summary) => SyncSummaryWidget(
                  summary: summary,
                  doneLabel: _doneLabel,
                  onDonePressed: () => _onDonePressed(context),
                ),
                IdleSyncState() || FailedSyncState() => Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    Icon(Icons.sync, size: _iconSize, color: theme.colorScheme.primary),
                    const SizedBox(height: AppTheme.spacingMedium),
                    Text(_intro, textAlign: TextAlign.center, style: theme.textTheme.bodyMedium),
                    if (state case FailedSyncState(:final String message)) ...<Widget>[
                      const SizedBox(height: AppTheme.spacingMedium),
                      Text(
                        message,
                        textAlign: TextAlign.center,
                        style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.error),
                      ),
                    ],
                    const SizedBox(height: AppTheme.spacingLarge),
                    FilledButton.icon(
                      onPressed: startSyncHostingUseCase.call,
                      icon: const Icon(Icons.qr_code_2),
                      label: const Text(_showQrLabel),
                    ),
                    if (_canScan) ...<Widget>[
                      const SizedBox(height: AppTheme.spacingSmall),
                      OutlinedButton.icon(
                        onPressed: () => _scan(context),
                        icon: const Icon(Icons.qr_code_scanner),
                        label: const Text(_scanLabel),
                      ),
                    ],
                    const SizedBox(height: AppTheme.spacingLarge),
                    Text(_orLabel, textAlign: TextAlign.center, style: theme.textTheme.labelMedium),
                    const SizedBox(height: AppTheme.spacingSmall),
                    TextField(
                      controller: syncPageController.codeController,
                      decoration: const InputDecoration(hintText: _codeHint, border: OutlineInputBorder()),
                    ),
                    const SizedBox(height: AppTheme.spacingSmall),
                    OutlinedButton(
                      onPressed: () => _connectTyped(syncPageController),
                      child: const Text(_connectLabel),
                    ),
                  ],
                ),
              },
            ),
          ),
        ),
      ),
    );
  }

  /// The camera scanner exists on phones and on the Mac.
  static bool get _canScan =>
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.android ||
          defaultTargetPlatform == TargetPlatform.iOS ||
          defaultTargetPlatform == TargetPlatform.macOS);

  static SyncPageController _createSyncPageController() => SyncPageController();

  /// New conflicts start with the safe choices.
  static void _onStateChanged(SyncPageController syncPageController, SyncState state) {
    if (state case ConflictsSyncState(:final List<SyncConflict> conflicts)) syncPageController.resetChoices(conflicts);
  }

  static Future<void> _resolve(SyncPageController syncPageController) async {
    await resolveSyncConflictsUseCase(syncPageController.choicesController.value);
  }

  static void _disposeSyncPageController(SyncPageController syncPageController) => syncPageController.dispose();

  /// Leaving the page stops waiting for the other device (an exchange in progress goes on).
  static void _onPopped(bool didPop, Object? result) {
    if (watchSyncStateUseCase().value is SyncingSyncState) return;
    stopSyncUseCase();
  }

  Future<void> _scan(BuildContext context) async {
    final String? code = await Navigator.of(
      context,
    ).push<String>(MaterialPageRoute<String>(builder: (BuildContext context) => const SyncScannerPage()));
    if (code == null) return;
    await _connect(code);
  }

  static Future<void> _connectTyped(SyncPageController syncPageController) =>
      _connect(syncPageController.codeController.text);

  static Future<void> _connect(String code) async {
    final Result<void> result = await syncWithDeviceUseCase(code);
    if (result.isFailure) return; // The page shows the failure from the state.
  }

  static Future<void> _copy(ScaffoldMessengerState messenger, String code) async {
    await Clipboard.setData(ClipboardData(text: code));
    messenger.showSnackBar(const SnackBar(content: Text(_copiedMessage)));
  }

  Future<void> _onDonePressed(BuildContext context) async {
    await stopSyncUseCase();
    if (!context.mounted) return;
    Navigator.of(context).pop();
  }
}
