import 'package:flutter/widgets.dart' show FocusNode, TextEditingController, ValueNotifier;

import '../../../../core/domain/entities/result_state.dart';
import '../../domain/entities/auth_failure.dart';

/// UI state of the authentication form, like a Flutter controller: the fields,
/// the mode, the password visibility and the progress of submitting.
///
/// Knows nothing about use cases: the form widget signs in or up and records
/// the outcome in [submittingStateController].
final class AuthFormController {
  /// Text of the email field.
  final TextEditingController emailController = TextEditingController();

  /// Text of the password field.
  final TextEditingController passwordController = TextEditingController();

  /// Focus of the email field.
  final FocusNode emailFocusNode = FocusNode();

  /// Focus of the password field.
  final FocusNode passwordFocusNode = FocusNode();

  /// Whether the form creates a new account instead of signing in.
  final ValueNotifier<bool> signUpModeController = ValueNotifier<bool>(false);

  /// Whether the password is hidden.
  final ValueNotifier<bool> passwordHiddenController = ValueNotifier<bool>(true);

  /// Progress of the last sign-in or sign-up; its failure is shown above the fields.
  final ValueNotifier<ResultState<void, AuthFailure>> submittingStateController =
      ValueNotifier<ResultState<void, AuthFailure>>(ResultState.idle);

  bool _isDisposed = false;

  /// Whether [dispose] was called; the owner checks it after every `await`.
  bool get isDisposed => _isDisposed;

  /// Entered email without surrounding spaces.
  String get email => emailController.text.trim();

  /// Entered password as typed.
  String get password => passwordController.text;

  /// Whether the email or the password is empty.
  bool get hasEmptyFields => email.isEmpty || password.isEmpty;

  /// Switches between sign-in and sign-up and clears the last error.
  void toggleMode() {
    signUpModeController.value = !signUpModeController.value;
    submittingStateController.value = ResultState.idle;
  }

  /// Shows or hides the password.
  void togglePasswordVisibility() {
    passwordHiddenController.value = !passwordHiddenController.value;
  }

  /// Moves focus from the email to the password field.
  void focusPassword() {
    passwordFocusNode.requestFocus();
  }

  /// Releases the fields and notifiers. Called by the owner (`createOnce(..., dispose: ...)`).
  void dispose() {
    _isDisposed = true;
    emailController.dispose();
    passwordController.dispose();
    emailFocusNode.dispose();
    passwordFocusNode.dispose();
    signUpModeController.dispose();
    passwordHiddenController.dispose();
    submittingStateController.dispose();
  }
}
