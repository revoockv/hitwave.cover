import 'package:flutter/material.dart';

/// One labelled slider of the control panel with its value on the right.
final class LyricsSliderRowWidget extends StatelessWidget {
  /// Text before the slider.
  final String label;

  /// Width of [label], the same for every row.
  final double labelWidth;

  /// Current value.
  final double value;

  /// Lowest value.
  final double min;

  /// Highest value.
  final double max;

  /// Number of slider steps.
  final int divisions;

  /// [value] as shown on the right and in the slider bubble.
  final String valueText;

  /// Called while the user drags.
  final ValueChanged<double> onChanged;

  /// Called when the user releases the slider.
  final ValueChanged<double> onChangeEnd;

  /// Creates a new [LyricsSliderRowWidget].
  const LyricsSliderRowWidget({
    super.key,
    required this.label,
    required this.labelWidth,
    required this.value,
    required this.min,
    required this.max,
    required this.divisions,
    required this.valueText,
    required this.onChanged,
    required this.onChangeEnd,
  });

  @override
  Widget build(BuildContext context) {
    final ColorScheme colorScheme = Theme.of(context).colorScheme;
    final TextTheme textTheme = Theme.of(context).textTheme;

    return Row(
      children: <Widget>[
        SizedBox(
          width: labelWidth,
          child: Text(label, style: textTheme.labelLarge?.copyWith(color: colorScheme.onSurfaceVariant)),
        ),
        Expanded(
          child: Slider(
            value: value,
            min: min,
            max: max,
            divisions: divisions,
            label: valueText,
            onChanged: onChanged,
            onChangeEnd: onChangeEnd,
          ),
        ),
        Text(
          valueText,
          style: textTheme.labelLarge?.copyWith(
            color: colorScheme.primary,
            fontFeatures: const <FontFeature>[FontFeature.tabularFigures()],
          ),
        ),
      ],
    );
  }
}
