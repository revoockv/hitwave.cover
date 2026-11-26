import 'package:flutter/material.dart';

import '../../../../core/presentation/theme.dart';

/// A red dot, the time and the input level of the take being recorded.
///
/// Dumb: the time and the level come from its wrapper, which watches the recorder ticks.
final class RecordingIndicatorWidget extends StatelessWidget {
  /// Size of the red dot.
  static const double _dotSize = 10;

  /// Width of the input level bar.
  static const double _levelBarWidth = 48;

  /// Digits of the minutes and seconds.
  static const int _timeDigits = 2;

  /// Separator of minutes and seconds.
  static const String _timeSeparator = ':';

  /// Padding character of the time.
  static const String _zero = '0';

  /// How long the take has been recorded.
  final Duration elapsed;

  /// The input level, 0 to 1.
  final double level;

  /// Creates a new [RecordingIndicatorWidget].
  const RecordingIndicatorWidget({super.key, required this.elapsed, required this.level});

  @override
  Widget build(BuildContext context) {
    final ColorScheme colorScheme = Theme.of(context).colorScheme;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Container(
          width: _dotSize,
          height: _dotSize,
          decoration: BoxDecoration(color: colorScheme.error, shape: BoxShape.circle),
        ),
        const SizedBox(width: AppTheme.spacingSmall),
        Text(
          _formatTime(elapsed),
          style: Theme.of(
            context,
          ).textTheme.labelLarge?.copyWith(fontFeatures: const <FontFeature>[FontFeature.tabularFigures()]),
        ),
        const SizedBox(width: AppTheme.spacingSmall),
        SizedBox(
          width: _levelBarWidth,
          child: LinearProgressIndicator(value: level, color: colorScheme.error),
        ),
      ],
    );
  }

  /// [time] as `mm:ss`.
  static String _formatTime(Duration time) {
    final int seconds = time.inSeconds;
    final String minutes = (seconds ~/ AppTheme.secondsPerMinute).toString().padLeft(_timeDigits, _zero);
    final String rest = (seconds % AppTheme.secondsPerMinute).toString().padLeft(_timeDigits, _zero);
    return '$minutes$_timeSeparator$rest';
  }
}
