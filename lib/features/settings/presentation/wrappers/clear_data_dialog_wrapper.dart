import 'package:flutter/material.dart';
import 'package:watch_it/watch_it.dart';

import '../../domain/entities/clearable_data.dart';
import '../controllers/clear_data_controller.dart';
import '../widgets/clear_data_dialog_widget.dart';

/// Gives [ClearDataDialogWidget] the data chosen in the page's [ClearDataController].
final class ClearDataDialogWrapper extends WatchingWidget {
  /// What is chosen, owned by the dialog's page.
  final ClearDataController clearDataController;

  /// The texts.
  final ClearDataDialogTexts texts;

  /// Called when the cancel button is pressed.
  final VoidCallback onCancelPressed;

  /// Called with the chosen data when the clear button is pressed.
  final ValueChanged<Set<ClearableData>> onClearPressed;

  /// Creates the wrapper.
  const ClearDataDialogWrapper({
    required this.clearDataController,
    required this.texts,
    required this.onCancelPressed,
    required this.onClearPressed,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final Set<ClearableData> selection = watch(clearDataController.selectionController).value;
    return ClearDataDialogWidget(
      selection: selection,
      texts: texts,
      onChanged: _onChanged,
      onCancelPressed: onCancelPressed,
      onClearPressed: () => onClearPressed(selection),
    );
  }

  void _onChanged(ClearableData data, bool chosen) {
    clearDataController.choose(data, chosen: chosen);
  }
}
