import 'package:flutter/foundation.dart' show ValueNotifier;

import '../../domain/entities/recording_version.dart';

/// UI state of a list of recordings: the version (original or enhanced) chosen on each card.
final class RecordingVersionsController {
  /// The version chosen on each card, by recording id; a card not in it shows the enhanced one.
  final ValueNotifier<Map<String, RecordingVersion>> versionsController = ValueNotifier<Map<String, RecordingVersion>>(
    const <String, RecordingVersion>{},
  );

  /// The version chosen on the card of [recordingId].
  RecordingVersion versionOf(String recordingId) => versionsController.value[recordingId] ?? RecordingVersion.enhanced;

  /// Chooses [version] on the card of [recordingId] only.
  void choose(String recordingId, RecordingVersion version) {
    versionsController.value = <String, RecordingVersion>{...versionsController.value, recordingId: version};
  }

  /// Disposes the notifier.
  void dispose() {
    versionsController.dispose();
  }
}
