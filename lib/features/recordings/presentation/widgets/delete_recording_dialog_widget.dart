import 'package:flutter/material.dart';

import '../../../../core/presentation/l10n/app_translations.dart';

/// Confirmation dialog for deleting a recording.
///
/// Pops `true` when the user confirms and `false` when they cancel.
final class DeleteRecordingDialogWidget extends StatelessWidget {
  /// Creates a new [DeleteRecordingDialogWidget].
  const DeleteRecordingDialogWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final Translations t = context.t;
    final ColorScheme colorScheme = Theme.of(context).colorScheme;

    return AlertDialog(
      icon: Icon(Icons.delete_outline, color: colorScheme.error),
      title: Text(t.recordings.deleteTitle),
      content: Text(t.recordings.deleteMessage),
      actions: <Widget>[
        TextButton(onPressed: () => _onCancelPressed(context), child: Text(t.common.cancel)),
        FilledButton(
          style: FilledButton.styleFrom(backgroundColor: colorScheme.error, foregroundColor: colorScheme.onError),
          onPressed: () => _onDeletePressed(context),
          child: Text(t.common.delete),
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
