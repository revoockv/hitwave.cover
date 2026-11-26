import 'package:flutter/material.dart';

import '../../domain/entities/clearable_data.dart';

/// The texts of [ClearDataDialogWidget].
final class ClearDataDialogTexts {
  /// Title of the dialog.
  final String titleText;

  /// What clearing does.
  final String messageText;

  /// Label of the cancel button.
  final String cancelLabel;

  /// Label of the clear button.
  final String clearLabel;

  /// The name of the data as shown next to its checkbox.
  final String Function(ClearableData data) labelOf;

  /// Creates the texts.
  const ClearDataDialogTexts({
    required this.titleText,
    required this.messageText,
    required this.cancelLabel,
    required this.clearLabel,
    required this.labelOf,
  });
}

/// The dialog that asks what to clear: a checkbox per data, Cancel and Clear.
///
/// Dumb: the chosen data, the texts and the callbacks come from above; the covers checkbox is off while the songs are
/// chosen, because covers go with their songs.
final class ClearDataDialogWidget extends StatelessWidget {
  /// The data chosen to be cleared.
  final Set<ClearableData> selection;

  /// The texts.
  final ClearDataDialogTexts texts;

  /// Called with a data and whether it is chosen now.
  final void Function(ClearableData data, bool chosen) onChanged;

  /// Called when the cancel button is pressed.
  final VoidCallback onCancelPressed;

  /// Called when the clear button is pressed.
  final VoidCallback onClearPressed;

  /// Creates the dialog.
  const ClearDataDialogWidget({
    required this.selection,
    required this.texts,
    required this.onChanged,
    required this.onCancelPressed,
    required this.onClearPressed,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = Theme.of(context).colorScheme;
    final bool songsChosen = selection.contains(ClearableData.songs);

    return AlertDialog(
      icon: Icon(Icons.delete_sweep_outlined, color: colors.error),
      title: Text(texts.titleText),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Text(texts.messageText),
            for (final ClearableData data in ClearableData.values)
              CheckboxListTile(
                contentPadding: EdgeInsets.zero,
                value: selection.contains(data),
                title: Text(texts.labelOf(data)),
                onChanged: data == ClearableData.covers && songsChosen
                    ? null
                    : (bool? chosen) => onChanged(data, chosen ?? false),
              ),
          ],
        ),
      ),
      actions: <Widget>[
        TextButton(onPressed: onCancelPressed, child: Text(texts.cancelLabel)),
        FilledButton(
          style: FilledButton.styleFrom(backgroundColor: colors.error, foregroundColor: colors.onError),
          onPressed: selection.isEmpty ? null : onClearPressed,
          child: Text(texts.clearLabel),
        ),
      ],
    );
  }
}
