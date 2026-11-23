import '../../../../core/presentation/l10n/app_translations.dart';
import '../../domain/entities/history_failure.dart';

/// The text of a [HistoryFailure] shown to the user.
extension HistoryFailureText on HistoryFailure {
  /// The text of this failure in the language of [t].
  String text(Translations t) => switch (this) {
    HistoryFailure.save => t.history.failure.save,
    HistoryFailure.clear => t.history.failure.clear,
  };
}
