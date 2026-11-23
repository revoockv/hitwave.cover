import 'dart:ui';

import 'package:flutter/material.dart';

import '../theme.dart';

/// A panel in the style of the theme: frosted glass that blurs what is behind it, or a
/// neumorphic panel raised from the background by a light and a dark shadow.
///
/// Use it where a [Card] would go; [onTap] makes the whole panel tappable.
final class SurfaceWidget extends StatelessWidget {
  static const double _shadowOffset = 4;
  static const double _shadowBlur = 10;
  static const double _glassShadowBlur = 14;
  static const double _glassShadowOffset = 5;
  static const double _glassShadowSpread = -2;
  static const double _borderWidth = 1;

  /// The content.
  final Widget child;

  /// Space between the edge and [child].
  final EdgeInsetsGeometry padding;

  /// Space around the panel.
  final EdgeInsetsGeometry margin;

  /// Corner radius.
  final double radius;

  /// Called when the panel is tapped; `null` for a panel that does not react.
  final VoidCallback? onTap;

  /// Creates a panel.
  const SurfaceWidget({
    required this.child,
    this.padding = EdgeInsets.zero,
    this.margin = EdgeInsets.zero,
    this.radius = AppTheme.radiusLarge,
    this.onTap,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final SurfaceTheme surfaces = SurfaceTheme.of(context);
    final BorderRadius borderRadius = BorderRadius.circular(radius);
    final Widget content = Material(
      type: MaterialType.transparency,
      child: InkWell(
        onTap: onTap,
        borderRadius: borderRadius,
        child: Padding(padding: padding, child: child),
      ),
    );

    final Widget panel = switch (surfaces.style) {
      SurfaceStyle.glass => DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: borderRadius,
          boxShadow: <BoxShadow>[
            BoxShadow(
              color: surfaces.shade,
              blurRadius: _glassShadowBlur,
              spreadRadius: _glassShadowSpread,
              offset: const Offset(0, _glassShadowOffset),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: borderRadius,
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: surfaces.blur, sigmaY: surfaces.blur),
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: surfaces.panel,
                borderRadius: borderRadius,
                border: Border.all(color: surfaces.border, width: _borderWidth),
              ),
              child: content,
            ),
          ),
        ),
      ),
      SurfaceStyle.neumorphic => DecoratedBox(
        decoration: BoxDecoration(
          color: surfaces.panel,
          borderRadius: borderRadius,
          boxShadow: <BoxShadow>[
            BoxShadow(
              color: surfaces.highlight,
              blurRadius: _shadowBlur,
              offset: const Offset(-_shadowOffset, -_shadowOffset),
            ),
            BoxShadow(
              color: surfaces.shade,
              blurRadius: _shadowBlur,
              offset: const Offset(_shadowOffset, _shadowOffset),
            ),
          ],
        ),
        child: content,
      ),
    };
    return Padding(padding: margin, child: panel);
  }
}
