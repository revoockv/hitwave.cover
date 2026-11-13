import 'package:flutter/material.dart';
import 'package:watch_it/watch_it.dart';

import '../../../../core/presentation/l10n/app_translations.dart';
import '../controllers/clear_data_controller.dart';

/// Asks what to clear; returns the chosen data, or `null` when cancelled.
final class ClearDataDialogWidget extends WatchingWidget {
  /// Creates the dialog.
  const ClearDataDialogWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final Translations t = context.t;
    final ClearDataController clearDataController = createOnce(_createController, dispose: _disposeController);
    final Set<ClearableData> selection = watch(clearDataController.selectionController).value;
    final ColorScheme colors = Theme.of(context).colorScheme;
    final bool songsChosen = selection.contains(ClearableData.songs);

    return AlertDialog(
      icon: Icon(Icons.delete_sweep_outlined, color: colors.error),
      title: Text(t.settings.clearTitle),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Text(t.settings.clearMessage),
            for (final ClearableData data in ClearableData.values)
              CheckboxListTile(
                contentPadding: EdgeInsets.zero,
                value: selection.contains(data),
                title: Text(_labelOf(t, data)),
                onChanged: data == ClearableData.covers && songsChosen
                    ? null
                    : (bool? chosen) => clearDataController.choose(data, chosen: chosen ?? false),
              ),
          ],
        ),
      ),
      actions: <Widget>[
        TextButton(onPressed: () => _close(context, null), child: Text(t.common.cancel)),
        FilledButton(
          style: FilledButton.styleFrom(backgroundColor: colors.error, foregroundColor: colors.onError),
          onPressed: selection.isEmpty ? null : () => _close(context, selection),
          child: Text(t.settings.clear),
        ),
      ],
    );
  }

  static void _close(BuildContext context, Set<ClearableData>? selection) => Navigator.of(context).pop(selection);

  static ClearDataController _createController() => ClearDataController();

  static void _disposeController(ClearDataController clearDataController) => clearDataController.dispose();

  static String _labelOf(Translations t, ClearableData data) => switch (data) {
    ClearableData.songs => t.settings.clearSongs,
    ClearableData.covers => t.settings.clearCovers,
    ClearableData.practice => t.settings.clearPractice,
    ClearableData.history => t.settings.clearHistory,
  };
}
