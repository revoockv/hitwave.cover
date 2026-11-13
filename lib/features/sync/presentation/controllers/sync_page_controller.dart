import 'package:flutter/widgets.dart' show TextEditingController, ValueNotifier;

import '../../domain/entities/sync_conflict.dart';

/// UI state of the sync page: the code typed by hand and the choices made for the conflicts.
final class SyncPageController {
  /// The code typed or pasted by hand (on a device that cannot scan).
  final TextEditingController codeController = TextEditingController();

  /// The choice of every conflict by id.
  final ValueNotifier<Map<String, SyncChoice>> choicesController = ValueNotifier<Map<String, SyncChoice>>(
    const <String, SyncChoice>{},
  );

  /// Starts with the safe choice (nothing lost) for every one of [conflicts].
  void resetChoices(List<SyncConflict> conflicts) {
    choicesController.value = <String, SyncChoice>{
      for (final SyncConflict conflict in conflicts) conflict.id: conflict.choices.first,
    };
  }

  /// Chooses [choice] for [conflict].
  void choose(SyncConflict conflict, SyncChoice choice) {
    choicesController.value = <String, SyncChoice>{...choicesController.value, conflict.id: choice};
  }

  /// Chooses [choice] for every one of [conflicts] that offers it.
  void chooseForAll(List<SyncConflict> conflicts, SyncChoice choice) {
    choicesController.value = <String, SyncChoice>{
      ...choicesController.value,
      for (final SyncConflict conflict in conflicts)
        if (conflict.choices.contains(choice)) conflict.id: choice,
    };
  }

  /// Disposes the controllers.
  void dispose() {
    codeController.dispose();
    choicesController.dispose();
  }
}
