import 'package:flutter/widgets.dart' show TextEditingController, ValueNotifier;

import '../../domain/entities/sync_change.dart';

/// UI state of the sync page: the code typed by hand and the changes ticked for the synchronisation.
final class SyncPageController {
  /// The code typed or pasted by hand (on a device that cannot scan).
  final TextEditingController codeController = TextEditingController();

  /// Ids of the ticked changes.
  final ValueNotifier<Set<String>> chosenController = ValueNotifier<Set<String>>(const <String>{});

  /// Ticks the changes of [changes] that are chosen first.
  void resetChosen(List<SyncChange> changes) {
    chosenController.value = <String>{
      for (final SyncChange change in changes)
        if (change.chosenFirst) change.id,
    };
  }

  /// Ticks or unticks [change]; ticking it unticks the change it excludes.
  void setChosen(SyncChange change, bool isChosen) {
    final Set<String> chosen = Set<String>.of(chosenController.value);
    if (isChosen) {
      chosen.add(change.id);
      final String? excluded = change.excludes;
      if (excluded != null) chosen.remove(excluded);
    } else {
      chosen.remove(change.id);
    }
    chosenController.value = chosen;
  }

  /// Ticks or unticks every one of [changes]; ticking unticks the changes they exclude.
  void setAllChosen(List<SyncChange> changes, bool isChosen) {
    final Set<String> chosen = Set<String>.of(chosenController.value);
    for (final SyncChange change in changes) {
      if (isChosen) {
        chosen.add(change.id);
        final String? excluded = change.excludes;
        if (excluded != null) chosen.remove(excluded);
      } else {
        chosen.remove(change.id);
      }
    }
    chosenController.value = chosen;
  }

  /// Disposes the controllers.
  void dispose() {
    codeController.dispose();
    chosenController.dispose();
  }
}
