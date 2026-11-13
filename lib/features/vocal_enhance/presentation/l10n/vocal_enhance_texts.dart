import '../../../../core/presentation/l10n/app_translations.dart';
import '../../domain/entities/vocal_enhance_failure.dart';

/// The text of a [VocalEnhanceFailure] shown to the user.
extension VocalEnhanceFailureText on VocalEnhanceFailure {
  /// The text of this failure in the language of [t].
  String text(Translations t) => switch (this) {
    VocalEnhanceFailure.unavailable => t.vocalEnhance.failure.unavailable,
    VocalEnhanceFailure.analyze => t.vocalEnhance.failure.analyze,
    VocalEnhanceFailure.enhance => t.vocalEnhance.failure.enhance,
    VocalEnhanceFailure.samePath => t.vocalEnhance.failure.samePath,
    VocalEnhanceFailure.notWav => t.vocalEnhance.failure.notWav,
    VocalEnhanceFailure.negativeLeadIn => t.vocalEnhance.failure.negativeLeadIn,
  };
}
