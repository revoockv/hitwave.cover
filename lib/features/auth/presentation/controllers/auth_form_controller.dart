import 'package:flutter/widgets.dart' show FocusNode, TextEditingController, ValueNotifier;

import '../../../../core/domain/entities/result.dart';
import '../../../../core/domain/entities/result_state.dart';

/// Signs the user in or up with an email and a password.
typedef AuthAction = Future<Result<void>> Function({required String email, required String password});

/// UI logic of the authentication form: the fields, the mode and one
/// [ResultState] of the last sign-in or sign-up.
///
/// Knows nothing about DI or use cases — the owner passes the actions in.
/// The mode and the password visibility change on their own, so they are
/// separate notifiers.
final class AuthFormController extends ValueNotifier<ResultState<void>> {
  /// Error shown when a field is empty.
  static const String _emptyFieldsError = 'Будь ласка, заповніть всі поля.';

  /// Controller of the email field.
  final TextEditingController email = TextEditingController();

  /// Controller of the password field.
  final TextEditingController password = TextEditingController();

  /// Focus node of the email field.
  final FocusNode emailFocus = FocusNode();

  /// Focus node of the password field.
  final FocusNode passwordFocus = FocusNode();

  /// Whether the form creates a new account instead of signing in.
  final ValueNotifier<bool> isSignUp = ValueNotifier<bool>(false);

  /// Whether the password is hidden.
  final ValueNotifier<bool> obscurePassword = ValueNotifier<bool>(true);

  final AuthAction _signIn;

  final AuthAction _signUp;

  bool _isDisposed = false;

  /// Creates the controller with the actions it runs.
  AuthFormController({required this._signIn, required this._signUp}) : super(ResultState.idle);

  /// Signs in or up with the entered values; ignored while an attempt runs.
  Future<void> submit() async {
    if (value.isLoading) return;

    final String emailText = email.text.trim();
    final String passwordText = password.text;
    if (emailText.isEmpty || passwordText.isEmpty) {
      value = const ResultState<void>.failure(_emptyFieldsError);
      return;
    }

    value = ResultState.loading;
    final AuthAction action = isSignUp.value ? _signUp : _signIn;
    final Result<void> result = await action(email: emailText, password: passwordText);
    if (_isDisposed) return;

    value = ResultState.of(result);
  }

  /// Switches between sign-in and sign-up and clears the last error.
  void toggleMode() {
    isSignUp.value = !isSignUp.value;
    value = ResultState.idle;
  }

  /// Shows or hides the password.
  void togglePasswordVisibility() {
    obscurePassword.value = !obscurePassword.value;
  }

  /// Moves focus from the email to the password field.
  void focusPassword() {
    passwordFocus.requestFocus();
  }

  /// Releases the fields and notifiers. Called by the owner (`createOnce(..., dispose: ...)`).
  @override
  void dispose() {
    _isDisposed = true;
    email.dispose();
    password.dispose();
    emailFocus.dispose();
    passwordFocus.dispose();
    isSignUp.dispose();
    obscurePassword.dispose();
    super.dispose();
  }
}
