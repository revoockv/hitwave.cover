import 'package:flutter/material.dart';

import '../../domain/entities/user.dart';
import '../di/auth_getters.dart';

/// Displays a welcome screen for authenticated users with a sign-out option.
///
/// Shows the user's email and provides a sign-out button.
class SignedInView extends StatelessWidget {
  /// The currently signed-in user.
  final User user;

  /// Creates a new [SignedInView].
  const SignedInView({super.key, required this.user});

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

  Widget _buildUserEmail(BuildContext context) {
    return Text(
      user.email,
      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
          ),
      textAlign: TextAlign.center,
    );
  }

  Widget _buildSignOutButton(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 48.0,
      child: ElevatedButton(
        onPressed: () => _handleSignOut(context),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.red,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: const Text(
          'Вийти',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Spacer(),
              Icon(
                Icons.check_circle,
                size: 80,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(height: 24),
              Text(
                'Вітаємо!',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              _buildUserEmail(context),
              const SizedBox(height: 48),
              _buildSignOutButton(context),
              const Spacer(),
            ],
          ),
        ),
      ),
    );
  }
}
