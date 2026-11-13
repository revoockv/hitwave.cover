import 'package:flutter/material.dart';
import 'package:watch_it/watch_it.dart';

import '../../../../core/presentation/theme.dart';

import '../di/auth_getters.dart';
import '../../domain/entities/user.dart';

/// Displays a welcome screen for authenticated users with a sign-out option.
///
/// Watches the current session and shows user info when signed in.
final class SignedInWidget extends WatchingWidget {
  /// Size of the check-circle icon.
  static const double _iconSize = 80;

  /// Large spacing between columns.
  static const double _spacingLarge = 48;

  /// Red color extracted as static const for error snackbar.
  static const Color _errorColor = Colors.red;


  /// Error message text for sign-out failure.
  static const String _errorMessage = 'Помилка виходу з системи.';

  /// Creates a new [SignedInWidget].
  const SignedInWidget({super.key});

  /// Handles the sign-out action.
  ///
  /// Calls [signOutUseCase] and shows a snackbar with [_errorMessage] on failure.
  Future<void> _handleSignOut(BuildContext context) async {
    final result = await signOutUseCase();

    if (!context.mounted) return;

    if (result.isFailure) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(_errorMessage),
          backgroundColor: _errorColor,
        ),
      );
    }
  }

  /// Builds the signed-in welcome screen.
  @override
  Widget build(BuildContext context) {
    final User? user = watch(watchCurrentSessionUseCase()).value;

    if (user == null) {
      return const SizedBox.shrink();
    }

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppTheme.spacingLarge),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Spacer(),
              const _SignedIconWidget(size: _iconSize),
              const SizedBox(height: AppTheme.spacingMedium),
              const _SignedTitleWidget(),
              const SizedBox(height: AppTheme.spacingMedium),
              _SignedEmailWidget(email: user.email),
              const SizedBox(height: _spacingLarge),
              _SignedOutButtonWidget(onPressed: () => _handleSignOut(context)),
              const Spacer(),
            ],
          ),
        ),
      ),
    );
  }
}

/// Check-circle icon displayed on the signed-in screen.
class _SignedIconWidget extends StatelessWidget {
  /// Creates a new [_SignedIconWidget].
  const _SignedIconWidget({required this.size});

  /// The size of the icon.
  final double size;

  /// Builds the check-circle icon.
  @override
  Widget build(BuildContext context) {
    return Icon(
      Icons.check_circle,
      size: size,
      color: Theme.of(context).colorScheme.primary,
    );
  }
}

/// Welcome title displayed on the signed-in screen.
class _SignedTitleWidget extends StatelessWidget {
  /// Title text shown to the signed-in user.
  static const String _titleText = 'Вітаємо!';

  /// Creates a new [_SignedTitleWidget].
  const _SignedTitleWidget();

  /// Builds the welcome title text.
  @override
  Widget build(BuildContext context) {
    return Text(
      _titleText,
      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
      textAlign: TextAlign.center,
    );
  }
}

/// Email address displayed on the signed-in screen.
class _SignedEmailWidget extends StatelessWidget {
  /// Alpha value for the email text opacity.
  static const double _alpha = 0.7;

  /// Creates a new [_SignedEmailWidget].
  const _SignedEmailWidget({required this.email});

  /// The email address of the signed-in user.
  final String email;

  /// Builds the email display text.
  @override
  Widget build(BuildContext context) {
    return Text(
      email,
      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: _alpha),
          ),
      textAlign: TextAlign.center,
    );
  }
}

/// Sign-out button displayed on the signed-in screen.
class _SignedOutButtonWidget extends StatelessWidget {
  /// Height of the sign-out button.
  static const double _buttonHeight = 48;

  /// Border radius of the sign-out button.
  static const double _buttonRadius = 12;

  /// Font size for the sign-out button text.
  static const double _fontSize = 16;

  /// Text shown on the sign-out button.
  static const String _buttonText = 'Вийти';
  static const Color _errorColor = Colors.red;
  static const Color _buttonForegroundColor = Colors.white;

  /// Creates a new [_SignedOutButtonWidget].
  const _SignedOutButtonWidget({required this.onPressed});

  /// Callback invoked when the sign-out button is pressed.
  final VoidCallback onPressed;

  /// Builds the sign-out button.
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: _buttonHeight,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: _errorColor,
          foregroundColor: _buttonForegroundColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(_buttonRadius),
          ),
        ),
        child: const Text(
          _buttonText,
          style: TextStyle(
            fontSize: _fontSize,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}
