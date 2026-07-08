import 'package:flutter/material.dart';

import '../widgets/auth_form_widget.dart';

/// Main authentication page shown when the user is not signed in.
class AuthPage extends StatelessWidget {
  /// Creates a new [AuthPage].
  const AuthPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const AuthFormWidget();
  }
}
