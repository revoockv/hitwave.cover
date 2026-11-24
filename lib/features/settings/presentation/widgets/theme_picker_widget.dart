import 'package:flutter/material.dart';

import '../../domain/entities/app_theme_style.dart';

/// The looks of the app as radio buttons; [selected] is marked.
final class ThemePickerWidget extends StatelessWidget {
  /// The look of the app now.
  final AppThemeStyle selected;

  /// The name of a look as shown to the user.
  final String Function(AppThemeStyle style) labelOf;

  /// Called with the look the user picked.
  final ValueChanged<AppThemeStyle> onSelected;

  /// Creates the picker.
  const ThemePickerWidget({required this.selected, required this.labelOf, required this.onSelected, super.key});

  @override
  Widget build(BuildContext context) {
    return RadioGroup<AppThemeStyle>(
      groupValue: selected,
      onChanged: _onChanged,
      child: Column(
        children: <Widget>[
          for (final AppThemeStyle style in AppThemeStyle.values)
            RadioListTile<AppThemeStyle>(value: style, title: Text(labelOf(style)), secondary: Icon(_iconOf(style))),
        ],
      ),
    );
  }

  void _onChanged(AppThemeStyle? style) {
    if (style != null) onSelected(style);
  }

  static IconData _iconOf(AppThemeStyle style) => switch (style) {
    AppThemeStyle.glassLight => Icons.blur_on,
    AppThemeStyle.glassDark => Icons.blur_circular,
    AppThemeStyle.neumorphicLight => Icons.light_mode_outlined,
    AppThemeStyle.neumorphicDark => Icons.dark_mode_outlined,
  };
}
