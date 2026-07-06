import 'package:flutter/material.dart';

import '../di/auth_getters.dart';

/// Displays the sign-in / sign-up form for unauthenticated users.
///
/// Supports toggling between login and registration modes.
class AuthFormView extends StatefulWidget {
  /// Creates a new [AuthFormView].
  const AuthFormView({super.key});

  @override
  State<AuthFormView> createState() => _AuthFormViewState();
}

class _AuthFormViewState extends State<AuthFormView> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final FocusNode _emailFocus = FocusNode();
  final FocusNode _passwordFocus = FocusNode();

  bool _isSignUp = false;
  bool _isLoading = false;
  String? _errorMessage;

  static const double _paddingSize = 24.0;
  static const double _fieldSpacing = 16.0;
  static const double _buttonHeight = 48.0;
  static const double _buttonRadius = 12.0;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _emailFocus.dispose();
    _passwordFocus.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_emailController.text.trim().isEmpty ||
        _passwordController.text.trim().isEmpty) {
      setState(() {
        _errorMessage = 'Будь ласка, заповніть всі поля.';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final result = _isSignUp
        ? await signUpUseCase(
            email: _emailController.text.trim(),
            password: _passwordController.text,
          )
        : await signInUseCase(
            email: _emailController.text.trim(),
            password: _passwordController.text,
          );

    if (!mounted) return;

    setState(() {
      _isLoading = false;
    });

    if (result.isFailure) {
      setState(() {
        _errorMessage = result.errorMessage;
      });
      return;
    }

    if (mounted) {
      Navigator.of(context).pop();
    }
  }

  Widget _buildEmailField() {
    return Padding(
      padding: const EdgeInsets.only(bottom: _fieldSpacing),
      child: TextField(
        controller: _emailController,
        focusNode: _emailFocus,
        keyboardType: TextInputType.emailAddress,
        textInputAction: TextInputAction.next,
        onEditingComplete: () {
          _passwordFocus.requestFocus();
        },
        decoration: const InputDecoration(
          labelText: 'Email',
          border: OutlineInputBorder(),
          contentPadding: EdgeInsets.symmetric(
            horizontal: _paddingSize,
            vertical: 16.0,
          ),
        ),
      ),
    );
  }

  Widget _buildPasswordField() {
    return TextField(
      controller: _passwordController,
      focusNode: _passwordFocus,
      obscureText: true,
      textInputAction: TextInputAction.done,
      onEditingComplete: _submit,
      decoration: const InputDecoration(
        labelText: 'Пароль',
        border: OutlineInputBorder(),
        contentPadding: EdgeInsets.symmetric(
          horizontal: _paddingSize,
          vertical: 16.0,
        ),
      ),
    );
  }

  Widget _buildSubmitButton() {
    return SizedBox(
      width: double.infinity,
      height: _buttonHeight,
      child: ElevatedButton(
        onPressed: _isLoading ? null : _submit,
        style: ElevatedButton.styleFrom(
          backgroundColor: Theme.of(context).colorScheme.primary,
          foregroundColor: Theme.of(context).colorScheme.onPrimary,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(_buttonRadius),
          ),
        ),
        child: _isLoading
            ? const SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : Text(
                _isSignUp ? 'Зареєструватися' : 'Увійти',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
      ),
    );
  }

  Widget _buildToggleButton() {
    return TextButton(
      onPressed: () {
        setState(() {
          _isSignUp = !_isSignUp;
          _errorMessage = null;
        });
      },
      child: Text(
        _isSignUp
            ? 'Вже є акаунт? Увійти'
            : 'Немає акаунту? Зареєструватися',
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(_paddingSize),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 48),
              Text(
                _isSignUp ? 'Реєстрація' : 'Вхід',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              if (_errorMessage != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: _fieldSpacing),
                  child: Text(
                    _errorMessage!,
                    style: const TextStyle(
                      color: Colors.red,
                      fontSize: 14,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              _buildEmailField(),
              _buildPasswordField(),
              const SizedBox(height: 24),
              _buildSubmitButton(),
              const SizedBox(height: 16),
              _buildToggleButton(),
            ],
          ),
        ),
      ),
    );
  }
}
