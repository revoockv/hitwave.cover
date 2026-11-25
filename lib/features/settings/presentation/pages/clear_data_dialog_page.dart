import 'package:flutter/material.dart';
import 'package:watch_it/watch_it.dart';

import '../../../../core/presentation/l10n/app_translations.dart';
import '../../domain/entities/clearable_data.dart';
import '../controllers/clear_data_controller.dart';
import '../l10n/settings_texts.dart';
import '../wrappers/clear_data_dialog_wrapper.dart';

/// The clear-data dialog as a route of its own: owns the [ClearDataController] and returns the chosen data, or `null`
/// when cancelled. Never rebuilds — its wrapper selects the choice.
final class ClearDataDialogPage extends WatchingWidget {
  /// Creates the dialog.
  const ClearDataDialogPage({super.key});

  @override
  Widget build(BuildContext context) {
    final ClearDataController clearDataController = createOnce(_createController, dispose: _disposeController);
    return ClearDataDialogWrapper(
      clearDataController: clearDataController,
      texts: context.t.clearDataDialog,
      onCancelPressed: () => _close(context, null),
      onClearPressed: (Set<ClearableData> selection) => _close(context, selection),
    );
  }

  static void _close(BuildContext context, Set<ClearableData>? selection) => Navigator.of(context).pop(selection);

  static ClearDataController _createController() => ClearDataController();

  static void _disposeController(ClearDataController clearDataController) => clearDataController.dispose();
}
