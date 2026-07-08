import 'package:flutter/material.dart';
import 'package:watch_it/watch_it.dart';

import '../di/auth_getters.dart';
import '../../domain/entities/user.dart';

/// Displays a welcome screen for authenticated users with a sign-out option.
///
/// Watches the current session and shows user info when signed in.
class SignedInWidget extends WatchingWidget {
  const SignedInWidget({super.key});

  static const double _padding = 24;
  static const double _iconSize = 80;
  static const double _spacingSmall = 16;
  static const double _spacingLarge = 48;

  Future<void> _handleSignOut(BuildContext context) async {
    final result = await signOutUseCase();

    if (!context.mounted) return;

    if (result.isFailure) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Помилка виходу з системи.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final User? user = watchValue((watchUseCase) => watchCurrentSessionUseCase);

    if (user == null) {
      return const SizedBox.shrink();
    }

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(_padding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Spacer(),
              _SignedIcon(size: _iconSize),
              const SizedBox(height: _spacingSmall),
              const _SignedTitle(),
              const SizedBox(height: _spacingSmall),
              _SignedEmail(email: user.email),
              const SizedBox(height: _spacingLarge),
              _SignedOutButton(onPressed: () => _handleSignOut(context)),
              const Spacer(),
            ],
          ),
        ),
      ),
    );
  }
}

class _SignedIcon extends StatelessWidget {
  const _SignedIcon({required this.size});

  final double size;

  @override
  Widget build(BuildContext context) {
    return Icon(
      Icons.check_circle,
      size: size,
      color: Theme.of(context).colorScheme.primary,
    );
  }
}

class _SignedTitle extends StatelessWidget {
  const _SignedTitle();

  static const String _titleText = 'Вітаємо!';

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

class _SignedEmail extends StatelessWidget {
  const _SignedEmail({required this.email});

  static const double _alpha = 0.7;

  final String email;

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

class _SignedOutButton extends StatelessWidget {
  const _SignedOutButton({required this.onPressed});

  final VoidCallback onPressed;

  static const double _buttonHeight = 48;
  static const double _buttonRadius = 12;
  static const double _fontSize = 16;
  static const String _buttonText = 'Вийти';
  static const String _errorMessage = 'Помилка виходу з системи.';

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: _buttonHeight,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.red,
          foregroundColor: Colors.white,
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
