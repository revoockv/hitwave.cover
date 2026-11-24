import 'package:flutter/material.dart';

import 'practice_time_text_widget.dart';

/// Asks before a practice session is deleted; with takes, a checkbox deletes them too. Returns whether the takes go
/// too, or `null` when cancelled.
///
/// Dumb: it owns only the checkbox's notifier (plain Flutter); the texts come from above.
final class DeletePracticeDialogWidget extends StatefulWidget {
  /// Takes recorded during the session.
  final int takeCount;

  /// The texts.
  final PracticeTexts texts;

  /// Creates the dialog.
  const DeletePracticeDialogWidget({super.key, required this.takeCount, required this.texts});

  @override
  State<DeletePracticeDialogWidget> createState() => _DeletePracticeDialogWidgetState();
}

final class _DeletePracticeDialogWidgetState extends State<DeletePracticeDialogWidget> {
  late final ValueNotifier<bool> _withTakesController;

  @override
  void initState() {
    super.initState();
    _withTakesController = ValueNotifier<bool>(false);
  }

  @override
  void dispose() {
    _withTakesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final PracticeTexts texts = widget.texts;
    return ValueListenableBuilder<bool>(
      valueListenable: _withTakesController,
      builder: (BuildContext context, bool withTakes, Widget? child) => AlertDialog(
        title: Text(texts.deleteTitle),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(texts.deleteMessage),
            if (widget.takeCount > 0)
              CheckboxListTile(
                contentPadding: EdgeInsets.zero,
                controlAffinity: ListTileControlAffinity.leading,
                value: withTakes,
                onChanged: _onWithTakesChanged,
                title: Text(texts.deleteTakesLabel(widget.takeCount)),
              ),
          ],
        ),
        actions: <Widget>[
          TextButton(onPressed: _onCancelPressed, child: Text(texts.cancelLabel)),
          FilledButton(onPressed: () => _onDeletePressed(withTakes), child: Text(texts.deleteLabel)),
        ],
      ),
    );
  }

  void _onWithTakesChanged(bool? value) {
    _withTakesController.value = value ?? false;
  }

  void _onCancelPressed() {
    Navigator.of(context).pop();
  }

  void _onDeletePressed(bool withTakes) {
    Navigator.of(context).pop(withTakes);
  }
}
