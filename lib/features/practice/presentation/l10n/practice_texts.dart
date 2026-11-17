import '../../../../core/presentation/l10n/app_translations.dart';
import '../../domain/entities/practice_failure.dart';

/// The text of a [PracticeFailure] shown to the user.
extension PracticeFailureText on PracticeFailure {
  /// The text of this failure in the language of [t].
  String text(Translations t) => switch (this) {
    PracticeFailure.saveSession => t.practice.saveFailed,
    PracticeFailure.importSessions => t.practice.importFailed,
    PracticeFailure.deleteSession => t.practice.deleteFailed,
    PracticeFailure.clear => t.practice.clearFailed,
  };
}
