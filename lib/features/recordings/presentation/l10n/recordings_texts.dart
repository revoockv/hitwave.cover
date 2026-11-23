import '../../../../core/presentation/l10n/app_translations.dart';
import '../../domain/entities/enhance_failure.dart';
import '../../domain/entities/recordings_failure.dart';

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
