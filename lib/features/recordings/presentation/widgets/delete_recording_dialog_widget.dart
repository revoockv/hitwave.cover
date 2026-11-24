import 'package:flutter/material.dart';

import 'recording_tile_widget.dart';

/// Confirmation dialog for deleting a recording.
///
/// Pops `true` when the user confirms and `false` when they cancel.
final class DeleteRecordingDialogWidget extends StatelessWidget {
  /// The texts.
  final RecordingsTexts texts;

  /// Creates the dialog.
  const DeleteRecordingDialogWidget({super.key, required this.texts});

  @override
  Widget build(BuildContext context) {
    final ColorScheme colorScheme = Theme.of(context).colorScheme;

    return AlertDialog(
      icon: Icon(Icons.delete_outline, color: colorScheme.error),
      title: Text(texts.deleteTitle),
      content: Text(texts.deleteMessage),
      actions: <Widget>[
        TextButton(onPressed: () => _onCancelPressed(context), child: Text(texts.cancelLabel)),
        FilledButton(
          style: FilledButton.styleFrom(backgroundColor: colorScheme.error, foregroundColor: colorScheme.onError),
          onPressed: () => _onDeletePressed(context),
          child: Text(texts.deleteLabel),
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
