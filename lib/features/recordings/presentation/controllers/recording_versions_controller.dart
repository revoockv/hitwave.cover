import 'package:flutter/foundation.dart' show ValueNotifier;

import '../../domain/entities/recording_version.dart';

/// The version chosen on the cards of a list; a card nobody chose on shows the enhanced one.
final class ChosenVersions {
  /// No card chosen on yet.
  static const ChosenVersions none = ChosenVersions._(<String, RecordingVersion>{});

  final Map<String, RecordingVersion> _byRecordingId;

  const ChosenVersions._(this._byRecordingId);

  /// The version chosen on the card of [recordingId].
  RecordingVersion of(String recordingId) => _byRecordingId[recordingId] ?? RecordingVersion.enhanced;

  /// These choices with [version] chosen on the card of [recordingId].
  ChosenVersions withChoice(String recordingId, RecordingVersion version) =>
      ChosenVersions._(<String, RecordingVersion>{..._byRecordingId, recordingId: version});
}

/// UI state of a list of recordings: the version (original or enhanced) chosen on each card and
/// the cards whose MP3 is being made for sharing.
final class RecordingVersionsController {
  /// The version chosen on each card.
  final ValueNotifier<ChosenVersions> versionsController = ValueNotifier<ChosenVersions>(ChosenVersions.none);

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
  RecordingVersion versionOf(String recordingId) => versionsController.value.of(recordingId);

  /// Chooses [version] on the card of [recordingId] only.
  void choose(String recordingId, RecordingVersion version) {
    versionsController.value = versionsController.value.withChoice(recordingId, version);
  }

  /// Disposes the notifier.
  void dispose() {
    versionsController.dispose();
    sharingController.dispose();
  }
}
