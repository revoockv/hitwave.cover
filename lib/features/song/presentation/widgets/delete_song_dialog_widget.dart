import 'package:flutter/material.dart';

/// Confirmation dialog for deleting a song.
///
/// Pops `true` when the user confirms and `false` when they cancel.
final class DeleteSongDialogWidget extends StatelessWidget {
  /// Dialog title.
  static const String _title = 'Видалити пісню?';

  /// Text before the song name.
  static const String _messagePrefix = 'Пісню «';

  /// Text after the song name.
  static const String _messageSuffix = '» буде видалено назавжди.';

  /// Label of the cancel button.
  static const String _cancelLabel = 'Скасувати';

  /// Label of the delete button.
  static const String _deleteLabel = 'Видалити';

  /// Name of the song to delete.
  final String songName;

  /// Creates a new [DeleteSongDialogWidget].
  const DeleteSongDialogWidget({required this.songName, super.key});

  @override
  Widget build(BuildContext context) {
    final ColorScheme colorScheme = Theme.of(context).colorScheme;

    return AlertDialog(
      icon: Icon(Icons.delete_outline, color: colorScheme.error),
      title: const Text(_title),
      content: Text('$_messagePrefix$songName$_messageSuffix'),
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
