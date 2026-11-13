import 'package:flutter/material.dart';

import '../theme.dart';

/// The main action of a page (in place of a `FloatingActionButton.extended`) in the style of the
/// theme: an accent pill with a glow of its color for glass; a raised pill of the background
/// color with an accent icon and label for neumorphic, glowing like neon in the dark.
final class AccentActionButtonWidget extends StatelessWidget {
  static const double _height = 56;
  static const double _glowBlur = 20;
  static const double _glowOffset = 6;
  static const double _glowAlpha = 0.45;
  static const double _neonBlur = 10;
  static const double _neonAlpha = 0.7;
  static const double _shadowOffset = 4;
  static const double _shadowBlur = 10;

  /// The icon before the label.
  final IconData icon;

  /// The label.
  final String label;

  /// Called on a tap.
  final VoidCallback onPressed;

  /// Creates the button.
  const AccentActionButtonWidget({required this.icon, required this.label, required this.onPressed, super.key});

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final SurfaceTheme surfaces = SurfaceTheme.of(context);
    final Color accent = theme.colorScheme.primary;
    final bool isGlass = surfaces.style == SurfaceStyle.glass;
    final bool isNeon = !isGlass && theme.brightness == Brightness.dark;
    final Color foreground = isGlass ? AppTheme.onColor(accent) : accent;
    final List<Shadow> neon = isNeon
        ? <Shadow>[
            Shadow(
              color: accent.withValues(alpha: _neonAlpha),
              blurRadius: _neonBlur,
            ),
          ]
        : const <Shadow>[];
    final BorderRadius radius = BorderRadius.circular(_height / 2);

    return DecoratedBox(
      decoration: BoxDecoration(
        color: isGlass ? accent : surfaces.panel,
        borderRadius: radius,
        boxShadow: isGlass
            ? <BoxShadow>[
                BoxShadow(
                  color: accent.withValues(alpha: _glowAlpha),
                  blurRadius: _glowBlur,
                  offset: const Offset(0, _glowOffset),
                ),
              ]
            : <BoxShadow>[
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
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          onTap: onPressed,
          borderRadius: radius,
          child: SizedBox(
            height: _height,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppTheme.spacingLarge),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Icon(icon, color: foreground, shadows: neon),
                  const SizedBox(width: AppTheme.spacingSmall),
                  Text(
                    label,
                    style: theme.textTheme.labelLarge?.copyWith(color: foreground, shadows: neon),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
