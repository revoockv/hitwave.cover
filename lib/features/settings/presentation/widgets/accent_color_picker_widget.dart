import 'package:flutter/material.dart';

import '../../../../core/presentation/theme.dart';
import '../../domain/entities/accent_color.dart';

/// How an [AccentColor] is painted.
extension AccentColorPaint on AccentColor {
  /// The color.
  Color get color => switch (this) {
    AccentColor.orange => AppTheme.accentOrange,
    AccentColor.blue => AppTheme.accentBlue,
    AccentColor.indigo => AppTheme.accentIndigo,
    AccentColor.violet => AppTheme.accentViolet,
    AccentColor.pink => AppTheme.accentPink,
    AccentColor.red => AppTheme.accentRed,
    AccentColor.green => AppTheme.accentGreen,
    AccentColor.teal => AppTheme.accentTeal,
  };
}

/// The accent colors as round swatches; [selected] has a check mark.
final class AccentColorPickerWidget extends StatelessWidget {
  /// The accent now.
  final AccentColor selected;

  /// The name of a color as shown to the user.
  final String Function(AccentColor color) labelOf;

  /// Called with the color the user picked.
  final ValueChanged<AccentColor> onSelected;

  /// Creates the picker.
  const AccentColorPickerWidget({required this.selected, required this.labelOf, required this.onSelected, super.key});

  @override
  Widget build(BuildContext context) {
    final Color ring = Theme.of(context).colorScheme.onSurface;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppTheme.spacingMedium),
      child: Wrap(
        spacing: AppTheme.spacingMedium,
        runSpacing: AppTheme.spacingMedium,
        children: <Widget>[
          for (final AccentColor color in AccentColor.values)
            _SwatchWidget(
              color: color,
              label: labelOf(color),
              isSelected: color == selected,
              ring: ring,
              onSelected: onSelected,
            ),
        ],
      ),
    );
  }
}

/// One round swatch of [color]; a check mark and a ring when [isSelected].
final class _SwatchWidget extends StatelessWidget {
  static const double _size = 44;
  static const double _selectedBorderWidth = 3;

  final AccentColor color;
  final String label;
  final bool isSelected;
  final Color ring;
  final ValueChanged<AccentColor> onSelected;

  const _SwatchWidget({
    required this.color,
    required this.label,
    required this.isSelected,
    required this.ring,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: label,
      child: Semantics(
        selected: isSelected,
        button: true,
        label: label,
        child: InkResponse(
          onTap: _onTap,
          radius: _size / 2,
          child: Container(
            width: _size,
            height: _size,
            decoration: BoxDecoration(
              color: color.color,
              shape: BoxShape.circle,
              border: isSelected ? Border.all(color: ring, width: _selectedBorderWidth) : null,
            ),
            child: isSelected ? Icon(Icons.check, color: AppTheme.onColor(color.color)) : null,
          ),
        ),
      ),
    );
  }

  void _onTap() => onSelected(color);
}
