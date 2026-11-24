import '../../../../core/presentation/l10n/app_translations.dart';
import '../../domain/entities/enhance_failure.dart';
import '../../domain/entities/recordings_failure.dart';
import '../../domain/entities/recording.dart';
import '../../domain/entities/recording_status.dart';
import '../widgets/recording_tile_widget.dart';

/// The text of a [RecordingsFailure] shown to the user.
extension RecordingsFailureText on RecordingsFailure {
  /// The text of this failure in the language of [t].
  String text(Translations t) => switch (this) {
    RecordingsFailure.play => t.recordings.failure.play,
    RecordingsFailure.share => t.recordings.failure.share,
    RecordingsFailure.showInFolder => t.recordings.failure.showInFolder,
    RecordingsFailure.fileMissing => t.recordings.failure.fileMissing,
    RecordingsFailure.busy => t.recordings.failure.busy,
    RecordingsFailure.notRecording => t.recordings.failure.notRecording,
    RecordingsFailure.microphonePermission => t.recordings.failure.microphonePermission,
    RecordingsFailure.start => t.recordings.failure.start,
    RecordingsFailure.listMicrophones => t.recordings.failure.listMicrophones,
    RecordingsFailure.save => t.recordings.failure.save,
    RecordingsFailure.notFound => t.recordings.failure.notFound,
    RecordingsFailure.delete => t.recordings.failure.delete,
    RecordingsFailure.importRecordings => t.recordings.failure.importRecordings,
    RecordingsFailure.savePreferences => t.recordings.failure.savePreferences,
  };
}

/// The text of an [EnhanceFailure] shown to the user.
extension EnhanceFailureText on EnhanceFailure {
  /// The text of this failure in the language of [t].
  String text(Translations t) => switch (this) {
    EnhanceFailure.interrupted => t.recordings.enhanceFailure.interrupted,
    EnhanceFailure.unavailable => t.recordings.enhanceFailure.unavailable,
    EnhanceFailure.failed => t.recordings.enhanceFailure.failed,
  };
}

/// The texts of the recordings widgets in the language of these [Translations].
extension RecordingsWidgetTexts on Translations {
  /// The texts of every recordings widget.
  RecordingsTexts get recordingsTexts => RecordingsTexts(
    playTooltip: recordings.play,
    pauseTooltip: recordings.pause,
    shareTooltip: recordings.share,
    preparingMp3Tooltip: recordings.preparingMp3,
    showInFolderTooltip: recordings.showInFolder,
    retryLabel: recordings.retry,
    enhanceNowLabel: recordings.enhanceNow,
    deleteTooltip: common.delete,
    originalLabel: recordings.original,
    enhancedLabel: recordings.enhanced,
    statusOf: _statusOf,
    deleteTitle: recordings.deleteTitle,
    deleteMessage: recordings.deleteMessage,
    cancelLabel: common.cancel,
    deleteLabel: common.delete,
    microphoneTitle: recordings.microphoneTitle,
    microphoneHint: recordings.microphoneHint,
    systemMicrophoneLabel: recordings.systemMicrophone,
  );

  String _statusOf(Recording recording) => recording.isSilent
      ? recordings.silent
      : switch (recording.status) {
          RecordingStatus.recorded => recordings.notEnhanced,
          RecordingStatus.enhancing => recordings.enhancing,
          RecordingStatus.enhanced => recordings.enhanced,
          RecordingStatus.enhanceFailed => recording.enhanceFailure?.text(this) ?? recordings.notEnhanced,
        };
}
