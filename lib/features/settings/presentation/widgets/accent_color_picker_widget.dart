import 'package:flutter/material.dart';

import '../../../../core/presentation/l10n/app_translations.dart';
import '../../../../core/presentation/theme.dart';
import '../../domain/entities/accent_color.dart';
import '../l10n/settings_texts.dart';

/// The accent colors as round swatches; [selected] has a check mark.
final class AccentColorPickerWidget extends StatelessWidget {
  /// The accent now.
  final AccentColor selected;

  /// Called with the color the user picked.
  final ValueChanged<AccentColor> onSelected;

  /// Creates the picker.
  const AccentColorPickerWidget({required this.selected, required this.onSelected, super.key});

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
            _SwatchWidget(color: color, isSelected: color == selected, ring: ring, onSelected: onSelected),
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
  final bool isSelected;
  final Color ring;
  final ValueChanged<AccentColor> onSelected;

  const _SwatchWidget({required this.color, required this.isSelected, required this.ring, required this.onSelected});

  @override
  Widget build(BuildContext context) {
    final String name = color.text(context.t);
    return Tooltip(
      message: name,
      child: Semantics(
        selected: isSelected,
        button: true,
        label: name,
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
