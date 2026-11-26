import 'package:flutter/material.dart';

import '../theme.dart';

/// Fades the app in again when its language changes, so the texts do not jump; the pages keep their state.
///
/// Placed under the app's `Localizations` (in `MaterialApp.builder`).
final class LocaleFadeWidget extends StatefulWidget {
  /// The pages.
  final Widget child;

  /// Creates the fade.
  const LocaleFadeWidget({required this.child, super.key});

  @override
  State<LocaleFadeWidget> createState() => _LocaleFadeWidgetState();
}

final class _LocaleFadeWidgetState extends State<LocaleFadeWidget> with SingleTickerProviderStateMixin {
  /// How dim the texts are when the new language comes in.
  static const double _dimmest = 0.25;

  late final AnimationController _fadeController = AnimationController(
    vsync: this,
    duration: AppTheme.themeChange,
    value: 1,
  );
  late final Animation<double> _opacity = Tween<double>(
    begin: _dimmest,
    end: 1,
  ).animate(CurvedAnimation(parent: _fadeController, curve: AppTheme.themeChangeCurve));
  Locale? _locale;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final Locale locale = Localizations.localeOf(context);
    if (_locale != null && _locale != locale) _fadeController.forward(from: 0);
    _locale = locale;
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => FadeTransition(opacity: _opacity, child: widget.child);
}
