import 'package:flutter/material.dart';

/// The texts of [DeleteSongDialogWidget].
final class DeleteSongDialogTexts {
  /// Title of the dialog.
  final String titleText;

  /// What happens to the song, with its name.
  final String messageText;

  /// Label of the cancel button.
  final String cancelLabel;

  /// Label of the delete button.
  final String deleteLabel;

  /// Creates the texts.
  const DeleteSongDialogTexts({
    required this.titleText,
    required this.messageText,
    required this.cancelLabel,
    required this.deleteLabel,
  });
}

/// Confirmation dialog for deleting a song.
///
/// Pops `true` when the user confirms and `false` when they cancel. Dumb: the texts come from above.
final class DeleteSongDialogWidget extends StatelessWidget {
  /// The texts, with the song's name in the message.
  final DeleteSongDialogTexts texts;

  /// Creates a new [DeleteSongDialogWidget].
  const DeleteSongDialogWidget({required this.texts, super.key});

  @override
  Widget build(BuildContext context) {
    final ColorScheme colorScheme = Theme.of(context).colorScheme;

    return AlertDialog(
      icon: Icon(Icons.delete_outline, color: colorScheme.error),
      title: Text(texts.titleText),
      content: Text(texts.messageText),
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
