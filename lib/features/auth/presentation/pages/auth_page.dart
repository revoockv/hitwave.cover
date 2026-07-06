import 'package:flutter/material.dart';
import 'package:watch_it/watch_it.dart';

import '../../domain/repositories/auth_repository.dart';
import '../widgets/auth_form_view.dart';
import '../widgets/signed_in_view.dart';

/// Main authentication page that handles sign-in, sign-up, and sign-out.
///
/// Displays either the login/register form when not signed in, or a welcome
/// screen with sign-out button when signed in.
class AuthPage extends WatchingWidget {
  /// Creates a new [AuthPage].
  const AuthPage({super.key});

  @override
  Widget build(BuildContext context) {
    final session = watchValue((AuthRepository r) => r.session);
    final user = session;

    if (user != null) {
      return SignedInView(user: user);
    }

    return const AuthFormView();
  }
}
