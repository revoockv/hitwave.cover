import 'package:flutter/material.dart';
import '../../../../core/presentation/theme.dart';
import '../../domain/entities/accent_color.dart';
import 'accent_color_picker_widget.dart';

/// One round swatch of [color]; a check mark and a ring when [isSelected].
final class AccentSwatchWidget extends StatelessWidget {
  static const double _size = 44;
  static const double _selectedBorderWidth = 3;

  /// The accent color.
  final AccentColor color;

  /// Name of the color, as the tooltip.
  final String label;

  /// Whether it is the chosen color.
  final bool isSelected;

  /// Color of the ring around the chosen color.
  final Color ring;

  /// Called with the color when it is tapped.
  final ValueChanged<AccentColor> onSelected;

  /// Creates a new [AccentSwatchWidget].
  const AccentSwatchWidget({
    super.key,
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
