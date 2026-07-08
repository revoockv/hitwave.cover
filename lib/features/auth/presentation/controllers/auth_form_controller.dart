import 'package:flutter/material.dart';

/// Controller for the authentication form.
///
/// Manages all form state (email, password, loading, error, mode) with ValueNotifiers.
/// Used by [AuthForm] to replace setState with reactive state management.
final class AuthFormController {
  /// Controller for the email text field.
  late final TextEditingController emailController = TextEditingController();

  /// Controller for the password text field.
  late final TextEditingController passwordController = TextEditingController();

  /// Focus node for the email field.
  late final FocusNode emailFocus = FocusNode();

  /// Focus node for the password field.
  late final FocusNode passwordFocus = FocusNode();

  /// Whether the form is in sign-up mode.
  late final ValueNotifier<bool> isSignUp = ValueNotifier(false);

  /// Whether the form is currently submitting.
  late final ValueNotifier<bool> isLoading = ValueNotifier(false);

  /// Error message to display, or null if no error.
  late final ValueNotifier<String?> errorMessage = ValueNotifier(null);

  /// Resets all form state to initial values.
  ///
  /// Clears email and password fields, resets loading/error flags,
  /// and sets the form back to sign-in mode.
  void reset() {
    emailController.clear();
    passwordController.clear();
    isSignUp.value = false;
    isLoading.value = false;
    errorMessage.value = null;
  }

  /// Disposes all controllers and notifiers.
  ///
  /// Must be called when the owning widget is disposed to prevent memory leaks.
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    emailFocus.dispose();
    passwordFocus.dispose();
    isSignUp.dispose();
    isLoading.dispose();
    errorMessage.dispose();
  }
}
