import 'package:flutter/material.dart';
import 'package:watch_it/watch_it.dart';

/// Asks whether the recordings go with the export or the import.
///
/// Pops `true` (with recordings) or `false` (songs only) when confirmed, and `null` when cancelled.
final class BackupOptionsDialogWidget extends WatchingWidget {
  /// Label of the checkbox.
  static const String _includeRecordingsLabel = 'Включити записи';

  /// Explanation under the checkbox.
  static const String _includeRecordingsHint =
      'Записи зберігаються лише на цьому пристрої; з ними файл стає ZIP-архівом.';

  /// Label of the cancel button.
  static const String _cancelLabel = 'Скасувати';

  /// Dialog title.
  final String title;

  /// Text under the title.
  final String message;

  /// Label of the confirm button.
  final String confirmLabel;

  /// Creates a new [BackupOptionsDialogWidget].
  const BackupOptionsDialogWidget({super.key, required this.title, required this.message, required this.confirmLabel});

  @override
  Widget build(BuildContext context) {
    final ValueNotifier<bool> includeRecordingsController = createOnce(
      _createIncludeRecordingsController,
      dispose: _disposeIncludeRecordingsController,
    );
    final bool includeRecordings = watch(includeRecordingsController).value;

    return AlertDialog(
      title: Text(title),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(message),
          CheckboxListTile(
            contentPadding: EdgeInsets.zero,
            value: includeRecordings,
            onChanged: (bool? value) => _onIncludeRecordingsChanged(includeRecordingsController, value),
            title: const Text(_includeRecordingsLabel),
            subtitle: const Text(_includeRecordingsHint),
          ),
        ],
      ),
      actions: <Widget>[
        TextButton(onPressed: () => _onCancelPressed(context), child: const Text(_cancelLabel)),
        FilledButton(
          onPressed: () => _onConfirmPressed(context, includeRecordingsController),
          child: Text(confirmLabel),
        ),
      ],
    );
  }

  static ValueNotifier<bool> _createIncludeRecordingsController() => ValueNotifier<bool>(false);

  static void _disposeIncludeRecordingsController(ValueNotifier<bool> includeRecordingsController) =>
      includeRecordingsController.dispose();

  void _onIncludeRecordingsChanged(ValueNotifier<bool> includeRecordingsController, bool? value) {
    includeRecordingsController.value = value ?? false;
  }

  void _onCancelPressed(BuildContext context) {
    Navigator.of(context).pop();
  }

  void _onConfirmPressed(BuildContext context, ValueNotifier<bool> includeRecordingsController) {
    Navigator.of(context).pop(includeRecordingsController.value);
  }
}
