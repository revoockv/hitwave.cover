import 'package:flutter/material.dart';

import '../widgets/auth_form_widget.dart';

/// Main authentication page shown when the user is not signed in.
///
/// Displays the [AuthForm] widget for login and registration.
class AuthPage extends StatelessWidget {
  /// Creates a new [AuthPage].
  const AuthPage({super.key});

  /// Builds the authentication page with the [AuthForm] widget.
  @override
  Widget build(BuildContext context) {
    return const AuthFormWidget();
  }
}
