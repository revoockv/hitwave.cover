import 'package:flutter/material.dart';
import 'package:watch_it/watch_it.dart';

import '../../../../core/presentation/l10n/app_translations.dart';

/// Asks whether a practice session goes, and its takes with it.
///
/// Pops `true` (with its takes), `false` (only the practice) when confirmed, and `null` when
/// cancelled.
final class DeletePracticeDialogWidget extends WatchingWidget {
  /// How many takes were recorded during the session; with none, nothing is asked about takes.
  final int takeCount;

  /// Creates a new [DeletePracticeDialogWidget].
  const DeletePracticeDialogWidget({super.key, required this.takeCount});

  @override
  Widget build(BuildContext context) {
    final Translations t = context.t;
    final ValueNotifier<bool> withTakesController = createOnce(_createWithTakesController, dispose: _disposeController);
    final bool withTakes = watch(withTakesController).value;

    return AlertDialog(
      title: Text(t.practice.deleteTitle),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(t.practice.deleteMessage),
          if (takeCount > 0)
            CheckboxListTile(
              contentPadding: EdgeInsets.zero,
              controlAffinity: ListTileControlAffinity.leading,
              value: withTakes,
              onChanged: (bool? value) => _onWithTakesChanged(withTakesController, value),
              title: Text(t.practice.deleteTakes(n: takeCount)),
            ),
        ],
      ),
      actions: <Widget>[
        TextButton(onPressed: () => _onCancelPressed(context), child: Text(t.common.cancel)),
        FilledButton(onPressed: () => _onDeletePressed(context, withTakes), child: Text(t.common.delete)),
      ],
    );
  }

  static ValueNotifier<bool> _createWithTakesController() => ValueNotifier<bool>(false);

  static void _disposeController(ValueNotifier<bool> withTakesController) => withTakesController.dispose();

  void _onWithTakesChanged(ValueNotifier<bool> withTakesController, bool? value) {
    withTakesController.value = value ?? false;
  }

  void _onCancelPressed(BuildContext context) {
    Navigator.of(context).pop();
  }

  void _onDeletePressed(BuildContext context, bool withTakes) {
    Navigator.of(context).pop(withTakes);
  }
}
