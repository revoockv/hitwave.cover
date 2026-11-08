import 'package:flutter/material.dart';

import '../../../../core/presentation/theme.dart';
import '../controllers/auth_form_controller.dart';
import '../di/auth_getters.dart';

/// Main authentication form displayed for unauthenticated users.
///
/// Supports toggling between login and registration modes. Manages all
/// form state through [AuthFormController] with ValueNotifiers — no setState.
/// After a successful sign-in the app swaps to the home page by itself,
/// because the root widget watches the session.
class AuthFormWidget extends StatefulWidget {
  /// Creates a new [AuthFormWidget].
  const AuthFormWidget({super.key});

  @override
  State<AuthFormWidget> createState() => _AuthFormState();
}

class _AuthFormState extends State<AuthFormWidget> {
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
  /// Validates that both email and password fields are filled, then calls
  /// [signInUseCase] or [signUpUseCase] depending on the current mode.
  Future<void> _submit() async {
    final String email = _controller.emailController.text.trim();
    final String password = _controller.passwordController.text;

    if (email.isEmpty || password.isEmpty) {
      _controller.errorMessage.value = _validationError;
      return;
    }

    FocusScope.of(context).unfocus();
    _controller.isLoading.value = true;
    _controller.errorMessage.value = null;

    final result = _controller.isSignUp.value
        ? await signUpUseCase(email: email, password: password)
        : await signInUseCase(email: email, password: password);

    if (!mounted) return;

    _controller.isLoading.value = false;
    result.when(success: _onSubmitSucceeded, failure: _onSubmitFailed);
  }

  /// Nothing to do: the session change replaces this page with the home page.
  void _onSubmitSucceeded(void _) {}

  /// Shows the error of a failed sign-in or sign-up above the fields.
  void _onSubmitFailed(String error) {
    _controller.errorMessage.value = error;
  }

  /// Builds the authentication form UI.
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppTheme.spacingLarge),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: AppTheme.maxContentWidth),
              child: AutofillGroup(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    const _BrandHeaderWidget(),
                    const SizedBox(height: AppTheme.spacingExtraLarge),
                    _FormTitleWidget(controller: _controller),
                    const SizedBox(height: AppTheme.spacingLarge),
                    _ErrorMessageWidget(controller: _controller),
                    _EmailFieldWidget(controller: _controller),
                    const SizedBox(height: AppTheme.spacingMedium),
                    _PasswordFieldWidget(controller: _controller, onSubmitted: _submit),
                    const SizedBox(height: AppTheme.spacingLarge),
                    _SubmitButtonWidget(controller: _controller, onPressed: _submit),
                    const SizedBox(height: AppTheme.spacingSmall),
                    _ToggleButtonWidget(controller: _controller),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ── Sub-widgets ────────────────────────────────────────────────────

/// App logo and name at the top of the form.
class _BrandHeaderWidget extends StatelessWidget {
  /// Size of the logo tile.
  static const double _logoSize = 72;

  /// Size of the logo icon.
  static const double _logoIconSize = 40;

  /// Name of the app.
  static const String _appName = 'Hitwave Cover';

  /// Short description under the name.
  static const String _tagline = 'Тексти пісень і кавери завжди під рукою';

  /// Creates a new [_BrandHeaderWidget].
  const _BrandHeaderWidget();

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme colorScheme = theme.colorScheme;

    return Column(
      children: <Widget>[
        Container(
          width: _logoSize,
          height: _logoSize,
          decoration: BoxDecoration(
            color: colorScheme.primaryContainer,
            borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
          ),
          child: Icon(Icons.graphic_eq, size: _logoIconSize, color: colorScheme.onPrimaryContainer),
        ),
        const SizedBox(height: AppTheme.spacingMedium),
        Text(
          _appName,
          style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: AppTheme.spacingTiny),
        Text(
          _tagline,
          style: theme.textTheme.bodyMedium?.copyWith(color: colorScheme.onSurfaceVariant),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}

/// Title text that switches between sign-in and sign-up labels.
class _FormTitleWidget extends StatelessWidget {
  /// Text shown in sign-up mode.
  static const String _signUpText = 'Створіть акаунт';

  /// Text shown in sign-in mode.
  static const String _signInText = 'Увійдіть в акаунт';

  /// Creates a new [_FormTitleWidget].
  const _FormTitleWidget({required this.controller});

  /// The [AuthFormController] providing form state.
  final AuthFormController controller;

  /// Builds the form title text.
  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: controller.isSignUp,
      builder: (BuildContext context, bool isSignUp, Widget? child) {
        return Text(isSignUp ? _signUpText : _signInText, style: Theme.of(context).textTheme.titleLarge);
      },
    );
  }
}

/// Displays the error message when sign-in fails or fields are empty.
class _ErrorMessageWidget extends StatelessWidget {
  /// Creates a new [_ErrorMessageWidget].
  const _ErrorMessageWidget({required this.controller});

  /// The [AuthFormController] providing the error message.
  final AuthFormController controller;

  /// Builds the error message display.
  @override
  Widget build(BuildContext context) {
    final ColorScheme colorScheme = Theme.of(context).colorScheme;

    return ValueListenableBuilder<String?>(
      valueListenable: controller.errorMessage,
      builder: (BuildContext context, String? errorMessage, Widget? child) {
        if (errorMessage == null) return const SizedBox.shrink();
        return Padding(
          padding: const EdgeInsets.only(bottom: AppTheme.spacingMedium),
          child: Semantics(
            liveRegion: true,
            child: Container(
              padding: const EdgeInsets.all(AppTheme.spacingMedium),
              decoration: BoxDecoration(
                color: colorScheme.errorContainer,
                borderRadius: BorderRadius.circular(AppTheme.radius),
              ),
              child: Row(
                children: <Widget>[
                  Icon(Icons.error_outline, color: colorScheme.onErrorContainer),
                  const SizedBox(width: AppTheme.spacingSmall),
                  Expanded(
                    child: Text(errorMessage, style: TextStyle(color: colorScheme.onErrorContainer)),
                  ),
                ],
              ),
            ),
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
    return TextField(
      controller: controller.emailController,
      focusNode: controller.emailFocus,
      keyboardType: TextInputType.emailAddress,
      textInputAction: TextInputAction.next,
      autocorrect: false,
      autofillHints: const <String>[AutofillHints.email],
      onEditingComplete: _onEditingComplete,
      decoration: const InputDecoration(labelText: _emailLabelText, prefixIcon: Icon(Icons.mail_outline)),
    );
  }

  /// Moves focus to the password field when email editing completes.
  void _onEditingComplete() {
    controller.passwordFocus.requestFocus();
  }
}

/// Password text field with a show/hide toggle.
class _PasswordFieldWidget extends StatelessWidget {
  /// Label text for the password field.
  static const String _passwordLabelText = 'Пароль';

  /// Tooltip of the toggle while the password is hidden.
  static const String _showPasswordTooltip = 'Показати пароль';

  /// Tooltip of the toggle while the password is visible.
  static const String _hidePasswordTooltip = 'Сховати пароль';

  /// Creates a new [_PasswordFieldWidget].
  const _PasswordFieldWidget({required this.controller, required this.onSubmitted});

  /// The [AuthFormController] providing form state.
  final AuthFormController controller;

  /// Callback invoked when the user submits the password field.
  final VoidCallback onSubmitted;

  /// Builds the password text field.
  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: controller.obscurePassword,
      builder: (BuildContext context, bool obscure, Widget? child) {
        return TextField(
          controller: controller.passwordController,
          focusNode: controller.passwordFocus,
          obscureText: obscure,
          textInputAction: TextInputAction.done,
          autofillHints: const <String>[AutofillHints.password],
          onEditingComplete: onSubmitted,
          decoration: InputDecoration(
            labelText: _passwordLabelText,
            prefixIcon: const Icon(Icons.lock_outline),
            suffixIcon: IconButton(
              tooltip: obscure ? _showPasswordTooltip : _hidePasswordTooltip,
              icon: Icon(obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined),
              onPressed: _onToggleVisibility,
            ),
          ),
        );
      },
    );
  }

  void _onToggleVisibility() {
    controller.obscurePassword.value = !controller.obscurePassword.value;
  }
}

/// Submit button for the authentication form.
class _SubmitButtonWidget extends StatelessWidget {
  /// Text shown in sign-up mode.
  static const String _signUpText = 'Зареєструватися';

  /// Text shown in sign-in mode.
  static const String _signInText = 'Увійти';

  /// Creates a new [_SubmitButtonWidget].
  const _SubmitButtonWidget({required this.controller, required this.onPressed});

  /// The [AuthFormController] providing form state.
  final AuthFormController controller;

  /// Callback invoked when the submit button is pressed.
  final VoidCallback onPressed;

  /// Builds the submit button with loading state.
  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: controller.isLoading,
      builder: (BuildContext context, bool isLoading, Widget? child) {
        return FilledButton(
          onPressed: isLoading ? null : onPressed,
          child: isLoading
              ? const SizedBox.square(
                  dimension: AppTheme.loadingIndicatorSize,
                  child: CircularProgressIndicator(strokeWidth: AppTheme.loadingIndicatorStroke),
                )
              : ValueListenableBuilder<bool>(
                  valueListenable: controller.isSignUp,
                  builder: (BuildContext context, bool isSignUp, Widget? child) {
                    return Text(isSignUp ? _signUpText : _signInText);
                  },
                ),
        );
      },
    );
  }
}

/// Toggle button to switch between sign-in and sign-up modes.
class _ToggleButtonWidget extends StatelessWidget {
  /// Shown in sign-up mode (switches to sign-in).
  static const String _signedInText = 'Вже є акаунт? Увійти';

  /// Shown in sign-in mode (switches to sign-up).
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
      builder: (BuildContext context, bool isSignUp, Widget? child) {
        return TextButton(onPressed: _onTogglePressed, child: Text(isSignUp ? _signedInText : _signedOutText));
      },
    );
  }

  /// Toggles between sign-in and sign-up modes and clears errors.
  void _onTogglePressed() {
    controller.isSignUp.value = !controller.isSignUp.value;
    controller.errorMessage.value = null;
  }
}
