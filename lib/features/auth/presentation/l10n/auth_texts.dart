import '../../../../core/presentation/l10n/app_translations.dart';
import '../../domain/entities/auth_failure.dart';

/// The text of an [AuthFailure] shown to the user.
extension AuthFailureText on AuthFailure {
  /// The text of this failure in the language of [t].
  String text(Translations t) => switch (this) {
    AuthFailure.emptyFields => t.auth.failure.emptyFields,
    AuthFailure.invalidEmail => t.auth.failure.invalidEmail,
    AuthFailure.userNotFound => t.auth.failure.userNotFound,
    AuthFailure.wrongPassword => t.auth.failure.wrongPassword,
    AuthFailure.emailAlreadyInUse => t.auth.failure.emailAlreadyInUse,
    AuthFailure.weakPassword => t.auth.failure.weakPassword,
    AuthFailure.userDisabled => t.auth.failure.userDisabled,
    AuthFailure.tooManyRequests => t.auth.failure.tooManyRequests,
    AuthFailure.invalidCredential => t.auth.failure.invalidCredential,
    AuthFailure.signOut => t.auth.signOutFailed,
    AuthFailure.unknown => t.common.genericError,
  };
}
