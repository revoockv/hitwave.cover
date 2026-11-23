import 'package:flutter/material.dart';

import '../../../../core/presentation/l10n/app_translations.dart';

/// Confirmation dialog for deleting a song.
///
/// Pops `true` when the user confirms and `false` when they cancel.
final class DeleteSongDialogWidget extends StatelessWidget {
  /// Name of the song to delete.
  final String songName;

  /// Creates a new [DeleteSongDialogWidget].
  const DeleteSongDialogWidget({required this.songName, super.key});

  @override
  Widget build(BuildContext context) {
    final Translations t = context.t;
    final ColorScheme colorScheme = Theme.of(context).colorScheme;

    return AlertDialog(
      icon: Icon(Icons.delete_outline, color: colorScheme.error),
      title: Text(t.song.deleteTitle),
      content: Text(t.song.deleteMessage(name: songName)),
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
