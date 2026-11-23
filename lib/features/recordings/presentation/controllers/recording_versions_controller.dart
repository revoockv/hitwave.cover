import 'package:flutter/foundation.dart' show ValueNotifier;

import '../../domain/entities/recording_version.dart';

/// UI state of a list of recordings: the version (original or enhanced) chosen on each card and
/// the cards whose MP3 is being made for sharing.
final class RecordingVersionsController {
  /// The version chosen on each card, by recording id; a card not in it shows the enhanced one.
  final ValueNotifier<Map<String, RecordingVersion>> versionsController = ValueNotifier<Map<String, RecordingVersion>>(
    const <String, RecordingVersion>{},
  );

  /// Ids of the recordings whose MP3 is being made for sharing.
  final ValueNotifier<Set<String>> sharingController = ValueNotifier<Set<String>>(const <String>{});

  /// Whether the MP3 of [recordingId] is being made.
  bool isSharing(String recordingId) => sharingController.value.contains(recordingId);

  /// Marks the MP3 of [recordingId] as being made (or done, when [sharing] is `false`).
  void setSharing(String recordingId, {required bool sharing}) {
    sharingController.value =
        sharing ? <String>{...sharingController.value, recordingId} : <String>{...sharingController.value}
          ..remove(recordingId);
  }

  /// The version chosen on the card of [recordingId].
  RecordingVersion versionOf(String recordingId) => versionsController.value[recordingId] ?? RecordingVersion.enhanced;

  /// Chooses [version] on the card of [recordingId] only.
  void choose(String recordingId, RecordingVersion version) {
    versionsController.value = <String, RecordingVersion>{...versionsController.value, recordingId: version};
  }

  /// Disposes the notifier.
  void dispose() {
    versionsController.dispose();
    sharingController.dispose();
  }
}
