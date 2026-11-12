import 'package:flutter/material.dart';

/// Confirmation dialog for deleting a recording.
///
/// Pops `true` when the user confirms and `false` when they cancel.
final class DeleteRecordingDialogWidget extends StatelessWidget {
  /// Dialog title.
  static const String _title = 'Видалити запис?';

  /// Dialog text.
  static const String _message = 'Оригінал і покращений файл буде видалено з пристрою.';

  /// Label of the cancel button.
  static const String _cancelLabel = 'Скасувати';

  /// Label of the delete button.
  static const String _deleteLabel = 'Видалити';

  /// Creates a new [DeleteRecordingDialogWidget].
  const DeleteRecordingDialogWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final ColorScheme colorScheme = Theme.of(context).colorScheme;

    return AlertDialog(
      icon: Icon(Icons.delete_outline, color: colorScheme.error),
      title: const Text(_title),
      content: const Text(_message),
      actions: <Widget>[
        TextButton(onPressed: () => _onCancelPressed(context), child: const Text(_cancelLabel)),
        FilledButton(
          style: FilledButton.styleFrom(backgroundColor: colorScheme.error, foregroundColor: colorScheme.onError),
          onPressed: () => _onDeletePressed(context),
          child: const Text(_deleteLabel),
        ),
      ],
    );
  }

  void _onCancelPressed(BuildContext context) {
    Navigator.of(context).pop(false);
  }

  void _onDeletePressed(BuildContext context) {
    Navigator.of(context).pop(true);
  }
}
