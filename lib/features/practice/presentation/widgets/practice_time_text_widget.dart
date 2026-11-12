import 'package:flutter/material.dart';

import '../../../../core/presentation/theme.dart';

/// A practice time as text: "1 год 05 хв", "12 хв" or "менше хвилини".
final class PracticeTimeTextWidget extends StatelessWidget {
  static const String _hours = ' год ';
  static const String _minutes = ' хв';
  static const String _lessThanMinute = 'менше хвилини';
  static const String _none = '—';
  static const String _zero = '0';
  static const int _minutesPerHour = 60;

  /// The time.
  final Duration time;

  /// Style of the text.
  final TextStyle? style;

  /// Creates a new [PracticeTimeTextWidget].
  const PracticeTimeTextWidget({super.key, required this.time, this.style});

  @override
  Widget build(BuildContext context) {
    return Text(format(time), style: style);
  }

  /// The text of [time].
  static String format(Duration time) {
    if (time == Duration.zero) return _none;
    final int minutes = time.inMinutes;
    if (minutes == 0) return _lessThanMinute;
    if (minutes < _minutesPerHour) return '$minutes$_minutes';
    final String rest = (minutes % _minutesPerHour).toString().padLeft(AppTheme.twoDigits, _zero);
    return '${time.inHours}$_hours$rest$_minutes';
  }
}
