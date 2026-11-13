import 'package:flutter/foundation.dart' show ValueListenable;
import 'package:flutter/material.dart';
import 'package:watch_it/watch_it.dart';

import '../../../../core/domain/entities/result.dart';
import '../../../../core/domain/entities/result_state.dart';
import '../../../../core/presentation/l10n/app_translations.dart';
import '../../../../core/presentation/theme.dart';
import '../controllers/auth_form_controller.dart';
import '../l10n/auth_texts.dart';
import '../di/auth_getters.dart';
import '../../domain/entities/auth_failure.dart';

/// Main authentication form displayed for unauthenticated users.
///
/// Supports toggling between login and registration modes. The form state
/// lives in [AuthFormController]; this widget signs in or up itself, and each
/// part of the form watches only what it shows. After a successful sign-in
/// the app swaps to the home page by itself, because the root widget watches
/// the session.
final class AuthFormWidget extends WatchingWidget {
  /// Error shown when a field is empty.

  /// Creates a new [AuthFormWidget].
  const AuthFormWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final AuthFormController authFormController = createOnce(
      _createAuthFormController,
      dispose: _disposeAuthFormController,
    );

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
                    _FormTitleWidget(signUpMode: authFormController.signUpModeController),
                    const SizedBox(height: AppTheme.spacingLarge),
                    _ErrorMessageWidget(submittingState: authFormController.submittingStateController),
                    _EmailFieldWidget(authFormController: authFormController),
                    const SizedBox(height: AppTheme.spacingMedium),
                    _PasswordFieldWidget(
                      authFormController: authFormController,
                      onSubmit: () => _onSubmitPressed(authFormController),
                    ),
                    const SizedBox(height: AppTheme.spacingLarge),
                    _SubmitButtonWidget(
                      submittingState: authFormController.submittingStateController,
                      signUpMode: authFormController.signUpModeController,
                      onPressed: () => _onSubmitPressed(authFormController),
                    ),
                    const SizedBox(height: AppTheme.spacingSmall),
                    _ToggleButtonWidget(
                      signUpMode: authFormController.signUpModeController,
                      onPressed: authFormController.toggleMode,
                    ),
                    const SizedBox(height: AppTheme.spacingLarge),
                    _WithoutAccountButtonWidget(
                      submittingState: authFormController.submittingStateController,
                      onPressed: () => _onWithoutAccountPressed(authFormController),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  static AuthFormController _createAuthFormController() => AuthFormController();

  static void _disposeAuthFormController(AuthFormController authFormController) => authFormController.dispose();

  /// Signs in or up with the entered values; ignored while an attempt runs.
  Future<void> _onSubmitPressed(AuthFormController authFormController) async {
    final ValueNotifier<ResultState<void, AuthFailure>> submittingStateController =
        authFormController.submittingStateController;
    if (submittingStateController.value.isLoading) return;
    if (authFormController.hasEmptyFields) {
      submittingStateController.value = const ResultState<void, AuthFailure>.failure(AuthFailure.emptyFields);
      return;
    }
    submittingStateController.value = ResultState.loading;

    final String email = authFormController.email;
    final String password = authFormController.password;
    final Result<void, AuthFailure> result = authFormController.signUpModeController.value
        ? await signUpUseCase(email: email, password: password)
        : await signInUseCase(email: email, password: password);
    if (authFormController.isDisposed) return;

    submittingStateController.value = ResultState.of(result);
  }

  /// Starts using the app without an account; shows the error when that fails.
  Future<void> _onWithoutAccountPressed(AuthFormController authFormController) async {
    if (authFormController.submittingStateController.value.isLoading) return;

    final Result<void, AuthFailure> result = await continueWithoutAccountUseCase();
    if (authFormController.isDisposed || result.isSuccess) return;

    authFormController.submittingStateController.value = ResultState.of(result);
  }
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

  /// Creates a new [_BrandHeaderWidget].
  const _BrandHeaderWidget();

  @override
  Widget build(BuildContext context) {
    final Translations t = context.t;
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
          t.auth.tagline,
          style: theme.textTheme.bodyMedium?.copyWith(color: colorScheme.onSurfaceVariant),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}

/// Title text that switches between sign-in and sign-up labels.
final class _FormTitleWidget extends WatchingWidget {
  /// Whether the form is in sign-up mode.
  final ValueListenable<bool> signUpMode;

  /// Creates a new [_FormTitleWidget].
  const _FormTitleWidget({required this.signUpMode});

  @override
  Widget build(BuildContext context) {
    final Translations t = context.t;
    final bool signUp = watch(signUpMode).value;
    return Text(signUp ? t.auth.createAccount : t.auth.signInTitle, style: Theme.of(context).textTheme.titleLarge);
  }
}

/// Shows the error of the last attempt, or nothing.
final class _ErrorMessageWidget extends WatchingWidget {
  /// Progress of the last sign-in or sign-up.
  final ValueListenable<ResultState<void, AuthFailure>> submittingState;

  /// Creates a new [_ErrorMessageWidget].
  const _ErrorMessageWidget({required this.submittingState});

  @override
  Widget build(BuildContext context) {
    final ResultState<void, AuthFailure> current = watch(submittingState).value;
    if (current is! FailureResultState<void, AuthFailure>) {
      return const SizedBox.shrink();
    }

    final Translations t = context.t;
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
                child: Text(current.failure.text(t), style: TextStyle(color: colorScheme.onErrorContainer)),
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
  /// The [AuthFormController] owning the field.
  final AuthFormController authFormController;

  /// Creates a new [_EmailFieldWidget].
  const _EmailFieldWidget({required this.authFormController});

  @override
  Widget build(BuildContext context) {
    final Translations t = context.t;
    return TextField(
      controller: authFormController.emailController,
      focusNode: authFormController.emailFocusNode,
      keyboardType: TextInputType.emailAddress,
      textInputAction: TextInputAction.next,
      autocorrect: false,
      autofillHints: const <String>[AutofillHints.email],
      onEditingComplete: authFormController.focusPassword,
      decoration: InputDecoration(labelText: t.auth.email, prefixIcon: const Icon(Icons.mail_outline)),
    );
  }
}

/// Password text field with a show/hide toggle.
final class _PasswordFieldWidget extends WatchingWidget {
  /// The [AuthFormController] owning the field.
  final AuthFormController authFormController;

  /// Called when the user finishes typing the password.
  final VoidCallback onSubmit;

  /// Creates a new [_PasswordFieldWidget].
  const _PasswordFieldWidget({required this.authFormController, required this.onSubmit});

  @override
  Widget build(BuildContext context) {
    final Translations t = context.t;
    final bool obscure = watch(authFormController.passwordHiddenController).value;

    return TextField(
      controller: authFormController.passwordController,
      focusNode: authFormController.passwordFocusNode,
      obscureText: obscure,
      textInputAction: TextInputAction.done,
      autofillHints: const <String>[AutofillHints.password],
      onEditingComplete: onSubmit,
      decoration: InputDecoration(
        labelText: t.auth.password,
        prefixIcon: const Icon(Icons.lock_outline),
        suffixIcon: IconButton(
          tooltip: obscure ? t.auth.showPassword : t.auth.hidePassword,
          icon: Icon(obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined),
          onPressed: authFormController.togglePasswordVisibility,
        ),
      ),
    );
  }
}

/// Submit button that shows progress while the attempt runs.
final class _SubmitButtonWidget extends WatchingWidget {
  /// Progress of the last sign-in or sign-up.
  final ValueListenable<ResultState<void, AuthFailure>> submittingState;

  /// Whether the form is in sign-up mode.
  final ValueListenable<bool> signUpMode;

  /// Called when the button is pressed.
  final VoidCallback onPressed;

  /// Creates a new [_SubmitButtonWidget].
  const _SubmitButtonWidget({required this.submittingState, required this.signUpMode, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    final Translations t = context.t;
    final bool isLoading = watch(submittingState).value.isLoading;
    final bool signUp = watch(signUpMode).value;

    return FilledButton(
      onPressed: isLoading ? null : onPressed,
      child: isLoading
          ? const SizedBox.square(
              dimension: AppTheme.loadingIndicatorSize,
              child: CircularProgressIndicator(strokeWidth: AppTheme.loadingIndicatorStroke),
            )
          : Text(signUp ? t.auth.signUp : t.auth.signIn),
    );
  }
}

/// Toggle button to switch between sign-in and sign-up modes.
final class _ToggleButtonWidget extends WatchingWidget {
  /// Whether the form is in sign-up mode.
  final ValueListenable<bool> signUpMode;

  /// Called when the button is pressed.
  final VoidCallback onPressed;

  /// Creates a new [_ToggleButtonWidget].
  const _ToggleButtonWidget({required this.signUpMode, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    final Translations t = context.t;
    final bool signUp = watch(signUpMode).value;
    return TextButton(onPressed: onPressed, child: Text(signUp ? t.auth.haveAccount : t.auth.noAccount));
  }
}

/// Button that starts using the app without an account, with a note where the songs are kept.
final class _WithoutAccountButtonWidget extends WatchingWidget {
  /// Progress of the last sign-in or sign-up; the button waits while it runs.
  final ValueListenable<ResultState<void, AuthFailure>> submittingState;

  /// Called when the button is pressed.
  final VoidCallback onPressed;

  /// Creates a new [_WithoutAccountButtonWidget].
  const _WithoutAccountButtonWidget({required this.submittingState, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    final Translations t = context.t;
    final bool isLoading = watch(submittingState).value.isLoading;
    final ThemeData theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        OutlinedButton.icon(
          onPressed: isLoading ? null : onPressed,
          icon: const Icon(Icons.phone_android),
          label: Text(t.auth.withoutAccount),
        ),
        const SizedBox(height: AppTheme.spacingSmall),
        Text(
          t.auth.withoutAccountNote,
          textAlign: TextAlign.center,
          style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
        ),
      ],
    );
  }
}
