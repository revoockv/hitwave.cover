import 'package:flutter/material.dart';

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
  State<AuthFormWidget> createState() => _AuthFormWidgetState();
}

class _AuthFormWidgetState extends State<AuthFormWidget> {
  late final AuthFormController _controller = AuthFormController();

  static const double _paddingSize = 24.0;
  static const double _topSpacing = 48.0;
  static const double _sectionSpacing = 32.0;
  static const double _buttonSpacing = 24.0;
  static const double _toggleSpacing = 16.0;
  static const String _validationError = 'Будь ласка, заповніть всі поля.';

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

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

    if (result.isFailure) {
      _controller.errorMessage.value = result.errorMessage;
      return;
    }

    if (mounted) {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(_paddingSize),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: _topSpacing),
              _FormTitle(controller: _controller),
              const SizedBox(height: _sectionSpacing),
              _ErrorMessage(controller: _controller),
              _EmailField(controller: _controller),
              _PasswordField(
                controller: _controller,
                onSubmitted: _submit,
              ),
              const SizedBox(height: _buttonSpacing),
              _SubmitButton(
                controller: _controller,
                onPressed: _submit,
              ),
              const SizedBox(height: _toggleSpacing),
              _ToggleButton(controller: _controller),
            ],
          ),
        ),
      ),
    );
  }
}

/// Title text that switches between sign-in and sign-up labels.
class _FormTitle extends StatelessWidget {
  const _FormTitle({required this.controller});

  final AuthFormController controller;

  static const double _headlineSpacing = 8.0;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: controller.isSignUp,
      builder: (context, isSignUp, child) {
        return Padding(
          padding: const EdgeInsets.only(bottom: _headlineSpacing),
          child: Text(
            isSignUp ? 'Реєстрація' : 'Вхід',
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
class _ErrorMessage extends StatelessWidget {
  const _ErrorMessage({required this.controller});

  final AuthFormController controller;

  static const double _errorFontSize = 14.0;
  static const double _errorBottomPadding = 16.0;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<String?>(
      valueListenable: controller.errorMessage,
      builder: (context, errorMessage, child) {
        if (errorMessage == null) return const SizedBox.shrink();
        return Padding(
          padding: EdgeInsets.only(bottom: _errorBottomPadding),
          child: Text(
            errorMessage,
            style: const TextStyle(
              color: Colors.red,
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
class _EmailField extends StatelessWidget {
  const _EmailField({required this.controller});

  final AuthFormController controller;

  static const double _fieldPaddingHorizontal = 24.0;
  static const double _fieldPaddingVertical = 16.0;
  static const double _fieldBottomSpacing = 16.0;
  static const String _emailLabelText = 'Email';

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: _fieldBottomSpacing),
      child: TextField(
        controller: controller.emailController,
        focusNode: controller.emailFocus,
        keyboardType: TextInputType.emailAddress,
        textInputAction: TextInputAction.next,
        onEditingComplete: _onEditingComplete,
        decoration: InputDecoration(
          labelText: _emailLabelText,
          border: const OutlineInputBorder(),
          contentPadding: EdgeInsets.symmetric(
            horizontal: _fieldPaddingHorizontal,
            vertical: _fieldPaddingVertical,
          ),
        ),
      ),
    );
  }

  void _onEditingComplete() {
    controller.passwordFocus.requestFocus();
  }
}

/// Password text field for the authentication form.
class _PasswordField extends StatelessWidget {
  const _PasswordField({required this.controller, required this.onSubmitted});

  final AuthFormController controller;
  final VoidCallback onSubmitted;

  static const double _fieldPaddingHorizontal = 24.0;
  static const double _fieldPaddingVertical = 16.0;
  static const String _passwordLabelText = 'Пароль';

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller.passwordController,
      focusNode: controller.passwordFocus,
      obscureText: true,
      textInputAction: TextInputAction.done,
      onEditingComplete: onSubmitted,
      decoration: InputDecoration(
        labelText: _passwordLabelText,
        border: const OutlineInputBorder(),
        contentPadding: EdgeInsets.symmetric(
          horizontal: _fieldPaddingHorizontal,
          vertical: _fieldPaddingVertical,
        ),
      ),
    );
  }
}

/// Submit button for the authentication form.
class _SubmitButton extends StatelessWidget {
  const _SubmitButton({required this.controller, required this.onPressed});

  final AuthFormController controller;
  final VoidCallback onPressed;

  static const double _buttonHeight = 48.0;
  static const double _buttonRadius = 12.0;
  static const double _indicatorSize = 20.0;
  static const double _strokeWidth = 2.0;
  static const double _buttonFontSize = 16.0;
  static const String _signUpText = 'Зареєструватися';
  static const String _signInText = 'Увійти';

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
                ? SizedBox(
                    height: _indicatorSize,
                    width: _indicatorSize,
                    child: CircularProgressIndicator(
                      strokeWidth: _strokeWidth,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
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
class _ToggleButton extends StatelessWidget {
  const _ToggleButton({required this.controller});

  final AuthFormController controller;

  static const String _signedInText = 'Вже є акаунт? Увійти';
  static const String _signedOutText = 'Немає акаунту? Зареєструватися';

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

  void _onTogglePressed() {
    controller.isSignUp.value = !controller.isSignUp.value;
    controller.errorMessage.value = null;
  }
}
