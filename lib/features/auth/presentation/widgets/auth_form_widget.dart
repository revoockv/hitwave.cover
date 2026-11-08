import 'package:flutter/foundation.dart' show ValueListenable;
import 'package:flutter/material.dart';
import 'package:watch_it/watch_it.dart';

import '../../../../core/domain/entities/result_state.dart';
import '../../../../core/presentation/theme.dart';
import '../controllers/auth_form_controller.dart';
import '../di/auth_getters.dart';

/// Main authentication form displayed for unauthenticated users.
///
/// Supports toggling between login and registration modes. All form state
/// lives in [AuthFormController]; each part of the form watches only what it
/// shows. After a successful sign-in the app swaps to the home page by
/// itself, because the root widget watches the session.
final class AuthFormWidget extends WatchingWidget {
  /// Creates a new [AuthFormWidget].
  const AuthFormWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final AuthFormController controller = createOnce(_createController, dispose: _disposeController);

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
                    _FormTitleWidget(isSignUp: controller.isSignUp),
                    const SizedBox(height: AppTheme.spacingLarge),
                    _ErrorMessageWidget(state: controller),
                    _EmailFieldWidget(controller: controller),
                    const SizedBox(height: AppTheme.spacingMedium),
                    _PasswordFieldWidget(controller: controller),
                    const SizedBox(height: AppTheme.spacingLarge),
                    _SubmitButtonWidget(state: controller, isSignUp: controller.isSignUp, onPressed: controller.submit),
                    const SizedBox(height: AppTheme.spacingSmall),
                    _ToggleButtonWidget(isSignUp: controller.isSignUp, onPressed: controller.toggleMode),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  static AuthFormController _createController() =>
      AuthFormController(signIn: signInUseCase.call, signUp: signUpUseCase.call);

  static void _disposeController(AuthFormController controller) => controller.dispose();
}

// ── Sub-widgets ────────────────────────────────────────────────────

/// App logo and name at the top of the form.
final class _BrandHeaderWidget extends StatelessWidget {
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
final class _FormTitleWidget extends WatchingWidget {
  /// Text shown in sign-up mode.
  static const String _signUpText = 'Створіть акаунт';

  /// Text shown in sign-in mode.
  static const String _signInText = 'Увійдіть в акаунт';

  /// Whether the form is in sign-up mode.
  final ValueListenable<bool> isSignUp;

  /// Creates a new [_FormTitleWidget].
  const _FormTitleWidget({required this.isSignUp});

  @override
  Widget build(BuildContext context) {
    final bool signUp = watch(isSignUp).value;
    return Text(signUp ? _signUpText : _signInText, style: Theme.of(context).textTheme.titleLarge);
  }
}

/// Shows the error of the last attempt, or nothing.
final class _ErrorMessageWidget extends WatchingWidget {
  /// State of the last sign-in or sign-up.
  final ValueListenable<ResultState<void>> state;

  /// Creates a new [_ErrorMessageWidget].
  const _ErrorMessageWidget({required this.state});

  @override
  Widget build(BuildContext context) {
    final ResultState<void> current = watch(state).value;
    if (current is! FailureResultState<void>) {
      return const SizedBox.shrink();
    }

    final ColorScheme colorScheme = Theme.of(context).colorScheme;
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
                child: Text(current.message, style: TextStyle(color: colorScheme.onErrorContainer)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Email text field for the authentication form.
final class _EmailFieldWidget extends StatelessWidget {
  /// Label text for the email field.
  static const String _emailLabelText = 'Email';

  /// The [AuthFormController] owning the field.
  final AuthFormController controller;

  /// Creates a new [_EmailFieldWidget].
  const _EmailFieldWidget({required this.controller});

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller.email,
      focusNode: controller.emailFocus,
      keyboardType: TextInputType.emailAddress,
      textInputAction: TextInputAction.next,
      autocorrect: false,
      autofillHints: const <String>[AutofillHints.email],
      onEditingComplete: controller.focusPassword,
      decoration: const InputDecoration(labelText: _emailLabelText, prefixIcon: Icon(Icons.mail_outline)),
    );
  }
}

/// Password text field with a show/hide toggle.
final class _PasswordFieldWidget extends WatchingWidget {
  /// Label text for the password field.
  static const String _passwordLabelText = 'Пароль';

  /// Tooltip of the toggle while the password is hidden.
  static const String _showPasswordTooltip = 'Показати пароль';

  /// Tooltip of the toggle while the password is visible.
  static const String _hidePasswordTooltip = 'Сховати пароль';

  /// The [AuthFormController] owning the field.
  final AuthFormController controller;

  /// Creates a new [_PasswordFieldWidget].
  const _PasswordFieldWidget({required this.controller});

  @override
  Widget build(BuildContext context) {
    final bool obscure = watch(controller.obscurePassword).value;

    return TextField(
      controller: controller.password,
      focusNode: controller.passwordFocus,
      obscureText: obscure,
      textInputAction: TextInputAction.done,
      autofillHints: const <String>[AutofillHints.password],
      onEditingComplete: controller.submit,
      decoration: InputDecoration(
        labelText: _passwordLabelText,
        prefixIcon: const Icon(Icons.lock_outline),
        suffixIcon: IconButton(
          tooltip: obscure ? _showPasswordTooltip : _hidePasswordTooltip,
          icon: Icon(obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined),
          onPressed: controller.togglePasswordVisibility,
        ),
      ),
    );
  }
}

/// Submit button that shows progress while the attempt runs.
final class _SubmitButtonWidget extends WatchingWidget {
  /// Text shown in sign-up mode.
  static const String _signUpText = 'Зареєструватися';

  /// Text shown in sign-in mode.
  static const String _signInText = 'Увійти';

  /// State of the last sign-in or sign-up.
  final ValueListenable<ResultState<void>> state;

  /// Whether the form is in sign-up mode.
  final ValueListenable<bool> isSignUp;

  /// Called when the button is pressed.
  final VoidCallback onPressed;

  /// Creates a new [_SubmitButtonWidget].
  const _SubmitButtonWidget({required this.state, required this.isSignUp, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    final bool isLoading = watch(state).value.isLoading;
    final bool signUp = watch(isSignUp).value;

    return FilledButton(
      onPressed: isLoading ? null : onPressed,
      child: isLoading
          ? const SizedBox.square(
              dimension: AppTheme.loadingIndicatorSize,
              child: CircularProgressIndicator(strokeWidth: AppTheme.loadingIndicatorStroke),
            )
          : Text(signUp ? _signUpText : _signInText),
    );
  }
}

/// Toggle button to switch between sign-in and sign-up modes.
final class _ToggleButtonWidget extends WatchingWidget {
  /// Shown in sign-up mode (switches to sign-in).
  static const String _signedInText = 'Вже є акаунт? Увійти';

  /// Shown in sign-in mode (switches to sign-up).
  static const String _signedOutText = 'Немає акаунту? Зареєструватися';

  /// Whether the form is in sign-up mode.
  final ValueListenable<bool> isSignUp;

  /// Called when the button is pressed.
  final VoidCallback onPressed;

  /// Creates a new [_ToggleButtonWidget].
  const _ToggleButtonWidget({required this.isSignUp, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    final bool signUp = watch(isSignUp).value;
    return TextButton(onPressed: onPressed, child: Text(signUp ? _signedInText : _signedOutText));
  }
}
