import 'package:flutter/material.dart';

import '../../../../core/presentation/theme.dart';

import '../di/auth_getters.dart';
import '../controllers/auth_form_controller.dart';

/// Main authentication form displayed for unauthenticated users.
///
/// Supports toggling between login and registration modes. Manages all
/// form state through [AuthFormController] with ValueNotifiers — no setState.
class AuthFormWidget extends StatefulWidget {
  /// Creates a new [AuthFormWidget].
  const AuthFormWidget({super.key});

  @override
  State<AuthFormWidget> createState() => _AuthFormState();
}

class _AuthFormState extends State<AuthFormWidget> {
  static const double _topSpacing = 48.0;
  static const double _sectionSpacing = 32.0;
  static const String _validationError = 'Будь ласка, заповніть всі поля.';

  late final AuthFormController _controller = AuthFormController();

  /// Disposes the form controller when the widget tree is removed.
  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  /// Submits the authentication form.
  ///
  /// Validates that both email and password fields are filled.
  /// Calls [signInUseCase] or [signUpUseCase] depending on the current mode,
  /// then pops the navigator on success or displays an error on failure.
  Future<void> _submit() async {
    final email = _controller.emailController.text.trim();
    final password = _controller.passwordController.text;

    if (email.isEmpty || password.isEmpty) {
      _controller.errorMessage.value = _validationError;
      return;
    }

    _controller.isLoading.value = true;
    _controller.errorMessage.value = null;

    final result = _controller.isSignUp.value
        ? await signUpUseCase(
            email: email,
            password: password,
          )
        : await signInUseCase(
            email: email,
            password: password,
          );

    if (!mounted) return;

    _controller.isLoading.value = false;

    result.when(success: _onSubmitSucceeded, failure: _onSubmitFailed);
  }

  /// Closes the form after a successful sign-in or sign-up.
  void _onSubmitSucceeded(void _) {
    Navigator.of(context).pop();
  }

  /// Shows the error of a failed sign-in or sign-up under the form.
  void _onSubmitFailed(String error) {
    _controller.errorMessage.value = error;
  }

  /// Builds the authentication form UI.
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppTheme.spacingLarge),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: _topSpacing),
               _FormTitleWidget(controller: _controller),
              const SizedBox(height: _sectionSpacing),
              _ErrorMessageWidget(controller: _controller),
              _EmailFieldWidget(controller: _controller),
              _PasswordFieldWidget(
                controller: _controller,
                onSubmitted: _submit,
              ),
              const SizedBox(height: AppTheme.spacingLarge),
              _SubmitButtonWidget(
                controller: _controller,
                onPressed: _submit,
              ),
              const SizedBox(height: AppTheme.spacingMedium),
               _ToggleButtonWidget(controller: _controller),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Sub-widgets ────────────────────────────────────────────────────

/// Title text that switches between sign-in and sign-up labels.
class _FormTitleWidget extends StatelessWidget {
  /// Text shown in sign-up mode.
  static const String _signUpText = 'Реєстрація';

  /// Text shown in sign-in mode.
  static const String _signInText = 'Вхід';

  /// Creates a new [_FormTitleWidget].
  const _FormTitleWidget({required this.controller});

  /// The [AuthFormController] providing form state.
  final AuthFormController controller;

  /// Builds the form title text.
  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: controller.isSignUp,
      builder: (context, isSignUp, child) {
        return Padding(
          padding: const EdgeInsets.only(bottom: AppTheme.spacingSmall),
            child: Text(
              isSignUp ? _signUpText : _signInText,
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
            textAlign: TextAlign.center,
          ),
        );
      },
    );
  }
}

/// Displays the error message when form validation fails.
class _ErrorMessageWidget extends StatelessWidget {
  /// Font size for error text.
  static const double _errorFontSize = 14.0;

  /// Error color extracted as static const.
  static const Color _errorColor = Colors.red;

  /// Creates a new [_ErrorMessageWidget].
  const _ErrorMessageWidget({required this.controller});

  /// The [AuthFormController] providing the error message.
  final AuthFormController controller;

  /// Builds the error message display.
  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<String?>(
      valueListenable: controller.errorMessage,
      builder: (context, errorMessage, child) {
        if (errorMessage == null) return const SizedBox.shrink();
        return Padding(
          padding: const EdgeInsets.only(bottom: AppTheme.spacingMedium),
          child: Text(
            errorMessage,
            style: const TextStyle(
              color: _errorColor,
              fontSize: _errorFontSize,
            ),
            textAlign: TextAlign.center,
          ),
        );
      },
    );
  }
}

/// Email text field for the authentication form.
class _EmailFieldWidget extends StatelessWidget {
  /// Label text for the email field.
  static const String _emailLabelText = 'Email';

  /// Creates a new [_EmailFieldWidget].
  const _EmailFieldWidget({required this.controller});

  /// The [AuthFormController] providing form state.
  final AuthFormController controller;

  /// Builds the email text field.
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppTheme.spacingMedium),
      child: TextField(
        controller: controller.emailController,
        focusNode: controller.emailFocus,
        keyboardType: TextInputType.emailAddress,
        textInputAction: TextInputAction.next,
        onEditingComplete: _onEditingComplete,
        decoration: const InputDecoration(
          labelText: _emailLabelText,
          border: OutlineInputBorder(),
          contentPadding: EdgeInsets.symmetric(
            horizontal: AppTheme.spacingLarge,
            vertical: AppTheme.spacingMedium,
          ),
        ),
      ),
    );
  }

  /// Moves focus to the password field when email editing completes.
  void _onEditingComplete() {
    controller.passwordFocus.requestFocus();
  }
}

/// Password text field for the authentication form.
class _PasswordFieldWidget extends StatelessWidget {
  /// Label text for the password field.
  static const String _passwordLabelText = 'Пароль';

  /// Creates a new [_PasswordFieldWidget].
  const _PasswordFieldWidget({
    required this.controller,
    required this.onSubmitted,
  });

  /// The [AuthFormController] providing form state.
  final AuthFormController controller;

  /// Callback invoked when the user submits the password field.
  final VoidCallback onSubmitted;

  /// Builds the password text field.
  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller.passwordController,
      focusNode: controller.passwordFocus,
      obscureText: true,
      textInputAction: TextInputAction.done,
      onEditingComplete: onSubmitted,
      decoration: const InputDecoration(
        labelText: _passwordLabelText,
        border: OutlineInputBorder(),
        contentPadding: EdgeInsets.symmetric(
          horizontal: AppTheme.spacingLarge,
          vertical: AppTheme.spacingMedium,
        ),
      ),
    );
  }
}

/// Submit button for the authentication form.
class _SubmitButtonWidget extends StatelessWidget {
  /// Height of the submit button.
  static const double _buttonHeight = 48.0;

  /// Border radius of the submit button.
  static const double _buttonRadius = 12.0;

  /// Size of the loading indicator.
  static const double _indicatorSize = 20.0;

  /// Stroke width of the loading indicator.
  static const double _strokeWidth = 2.0;

  /// Font size for the button text.
  static const double _buttonFontSize = 16.0;

  /// Text shown in sign-up mode.
  static const String _signUpText = 'Зареєструватися';

  /// Text shown in sign-in mode.
  static const String _signInText = 'Увійти';

  /// White color extracted as static const for the loading indicator.
  static const Color _whiteColor = Colors.white;

  /// Creates a new [_SubmitButtonWidget].
  const _SubmitButtonWidget({
    required this.controller,
    required this.onPressed,
  });

  /// The [AuthFormController] providing form state.
  final AuthFormController controller;

  /// Callback invoked when the submit button is pressed.
  final VoidCallback onPressed;

  /// Builds the submit button with loading state.
  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: controller.isLoading,
      builder: (context, isLoading, child) {
        return SizedBox(
          width: double.infinity,
          height: _buttonHeight,
          child: ElevatedButton(
            onPressed: isLoading ? null : onPressed,
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.primary,
              foregroundColor: Theme.of(context).colorScheme.onPrimary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(_buttonRadius),
              ),
            ),
            child: isLoading
                ? const SizedBox(
                    height: _indicatorSize,
                    width: _indicatorSize,
                    child: CircularProgressIndicator(
                      strokeWidth: _strokeWidth,
                      valueColor: AlwaysStoppedAnimation<Color>(_whiteColor),
                    ),
                  )
                : ValueListenableBuilder<bool>(
                    valueListenable: controller.isSignUp,
                    builder: (context, isSignUp, child) {
                      return Text(
                        isSignUp ? _signUpText : _signInText,
                        style: const TextStyle(
                          fontSize: _buttonFontSize,
                          fontWeight: FontWeight.w600,
                        ),
                      );
                    },
                  ),
          ),
        );
      },
    );
  }
}

/// Toggle button to switch between sign-in and sign-up modes.
class _ToggleButtonWidget extends StatelessWidget {
  /// Text shown when user is signed in (toggle to sign-in).
  static const String _signedInText = 'Вже є акаунт? Увійти';

  /// Text shown when user is signed out (toggle to sign-up).
  static const String _signedOutText = 'Немає акаунту? Зареєструватися';

  /// Creates a new [_ToggleButtonWidget].
  const _ToggleButtonWidget({required this.controller});

  /// The [AuthFormController] providing form state.
  final AuthFormController controller;

  /// Builds the toggle button.
  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: controller.isSignUp,
      builder: (context, isSignUp, child) {
        return TextButton(
          onPressed: _onTogglePressed,
          child: Text(isSignUp ? _signedInText : _signedOutText),
        );
      },
    );
  }

  /// Toggles between sign-in and sign-up modes and clears errors.
  void _onTogglePressed() {
    controller.isSignUp.value = !controller.isSignUp.value;
    controller.errorMessage.value = null;
  }
}
