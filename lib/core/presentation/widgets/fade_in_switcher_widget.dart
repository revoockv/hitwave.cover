import 'package:flutter/material.dart';

/// Shows [child] fading in and rising a little whenever [switchKey] changes (another tab, another mode).
///
/// The old child goes at once, so two copies of a page never live together: a page that holds the microphone
/// or a player frees it before the new one takes it.
final class FadeInSwitcherWidget extends StatelessWidget {
  static const Duration _duration = Duration(milliseconds: 280);
  static const double _rise = 12;

  /// What identifies the shown child; a new value starts the fade.
  final Object switchKey;

  /// The page.
  final Widget child;

  /// Creates the switcher.
  const FadeInSwitcherWidget({required this.switchKey, required this.child, super.key});

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      key: ValueKey<Object>(switchKey),
      tween: Tween<double>(begin: 0, end: 1),
      duration: _duration,
      curve: Curves.easeOutCubic,
      builder: (BuildContext context, double shown, Widget? child) => Opacity(
        opacity: shown,
        child: Transform.translate(offset: Offset(0, (1 - shown) * _rise), child: child),
      ),
      child: child,
    );
  }
}
