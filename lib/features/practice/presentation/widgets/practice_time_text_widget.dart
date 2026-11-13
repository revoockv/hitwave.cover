import 'package:flutter/material.dart';

import '../../../../core/presentation/l10n/app_translations.dart';
import '../../../../core/presentation/theme.dart';

/// A practice time as text: "1 h 05 min", "12 min" or "less than a minute".
final class PracticeTimeTextWidget extends StatelessWidget {
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
    return Text(format(context.t, time), style: style);
  }

  /// The text of [time] in the language of [t].
  static String format(Translations t, Duration time) {
    if (time == Duration.zero) return _none;
    final int minutes = time.inMinutes;
    if (minutes == 0) return t.practice.lessThanMinute;
    if (minutes < _minutesPerHour) return t.practice.minutes(minutes: minutes);
    final String rest = (minutes % _minutesPerHour).toString().padLeft(AppTheme.twoDigits, _zero);
    return t.practice.hoursMinutes(hours: time.inHours, minutes: rest);
  }
}
