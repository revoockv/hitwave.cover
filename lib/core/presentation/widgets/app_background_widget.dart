import 'package:flutter/material.dart';

import '../theme.dart';

/// The background under every page: a soft diagonal gradient for glass, tinted with the accent
/// at the bottom right; one flat color for neumorphic.
final class AppBackgroundWidget extends StatelessWidget {
  /// The pages.
  final Widget child;

  /// Creates the background.
  const AppBackgroundWidget({required this.child, super.key});

  /// `MaterialApp.builder` that puts the background under every page.
  static Widget wrap(BuildContext context, Widget? child) =>
      AppBackgroundWidget(child: child ?? const SizedBox.shrink());

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: SurfaceTheme.of(context).background,
        ),
      ),
      child: child,
    );
  }
}
