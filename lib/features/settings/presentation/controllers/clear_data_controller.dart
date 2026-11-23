import 'package:flutter/foundation.dart';

/// Data the user can clear.
enum ClearableData {
  /// Every song with its covers.
  songs,

  /// Every cover.
  covers,

  /// The practice statistics.
  practice,

  /// The recently opened songs and played covers.
  history,
}

/// UI state of the clear-data dialog: what is chosen to be cleared.
///
/// Knows nothing about use cases — the page clears what the dialog returns.
final class ClearDataController {
  /// What is chosen; covers stay chosen while the songs are, because they go with their songs.
  final ValueNotifier<Set<ClearableData>> selectionController = ValueNotifier<Set<ClearableData>>(
    const <ClearableData>{},
  );

  bool _isDisposed = false;

  /// Whether [dispose] was called.
  bool get isDisposed => _isDisposed;

  /// Chooses [data] when [chosen], else leaves it out.
  void choose(ClearableData data, {required bool chosen}) {
    final Set<ClearableData> selection = Set<ClearableData>.of(selectionController.value);
    if (chosen) {
      selection.add(data);
    } else {
      selection.remove(data);
    }
    if (selection.contains(ClearableData.songs)) selection.add(ClearableData.covers);
    selectionController.value = Set<ClearableData>.unmodifiable(selection);
  }

  /// Releases the notifier. Called by the owner (`createOnce(..., dispose: ...)`).
  void dispose() {
    _isDisposed = true;
    selectionController.dispose();
  }
}
