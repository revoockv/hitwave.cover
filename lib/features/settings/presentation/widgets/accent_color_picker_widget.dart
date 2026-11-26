import 'package:flutter/material.dart';

import '../../../../core/presentation/theme.dart';
import '../../domain/entities/accent_color.dart';
import 'accent_swatch_widget.dart';

/// How an [AccentColor] is painted.
extension AccentColorPaint on AccentColor {
  /// The color.
  Color get color => switch (this) {
    AccentColor.orange => AppTheme.accentOrange,
    AccentColor.gold => AppTheme.accentGold,
    AccentColor.olive => AppTheme.accentOlive,
    AccentColor.green => AppTheme.accentGreen,
    AccentColor.teal => AppTheme.accentTeal,
    AccentColor.azure => AppTheme.accentAzure,
    AccentColor.blue => AppTheme.accentBlue,
    AccentColor.indigo => AppTheme.accentIndigo,
    AccentColor.violet => AppTheme.accentViolet,
    AccentColor.lilac => AppTheme.accentLilac,
    AccentColor.pink => AppTheme.accentPink,
    AccentColor.raspberry => AppTheme.accentRaspberry,
    AccentColor.red => AppTheme.accentRed,
    AccentColor.coral => AppTheme.accentCoral,
    AccentColor.brown => AppTheme.accentBrown,
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
            AccentSwatchWidget(
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
