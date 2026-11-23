import 'package:flutter/material.dart';

import '../../../../core/presentation/theme.dart';
import '../../domain/entities/practice_day.dart';

/// One day of the practice calendar: the longer the practice, the stronger the colour; a small
/// dot when takes were recorded; a ring around today and the chosen day.
final class PracticeDayCellWidget extends StatelessWidget {
  /// Practice of a day that gives the strongest colour.
  static const Duration _fullDay = Duration(minutes: 30);

  /// The weakest colour of a day with practice.
  static const double _minOpacity = 0.25;
  static const double _takeDotSize = 5;
  static const double _selectedBorderWidth = 2;
  static const double _todayBorderWidth = 1;
  static const Color _noPracticeColor = Color(0x00000000);

  /// The day.
  final DateTime day;

  /// Its practice, or `null` when there was none.
  final PracticeDay? practice;

  /// Whether it is the chosen day.
  final bool isSelected;

  /// Whether it is today.
  final bool isToday;

  /// Called with [day] when tapped.
  final ValueChanged<DateTime> onSelected;

  /// Creates a new [PracticeDayCellWidget].
  const PracticeDayCellWidget({
    super.key,
    required this.day,
    required this.practice,
    required this.isSelected,
    required this.isToday,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme colors = theme.colorScheme;
    final PracticeDay? practice = this.practice;
    final double strength = practice == null
        ? 0
        : (_minOpacity + (1 - _minOpacity) * (practice.time.inSeconds / _fullDay.inSeconds)).clamp(_minOpacity, 1.0);
    final Color background = practice == null ? _noPracticeColor : colors.primary.withValues(alpha: strength);
    final Color text = practice != null && strength > (1 + _minOpacity) / 2 ? colors.onPrimary : colors.onSurface;

    return Padding(
      padding: const EdgeInsets.all(AppTheme.spacingTiny / 2),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: _onTap,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: background,
            shape: BoxShape.circle,
            border: isSelected || isToday
                ? Border.all(
                    color: isSelected ? colors.tertiary : colors.outline,
                    width: isSelected ? _selectedBorderWidth : _todayBorderWidth,
                  )
                : null,
          ),
          child: Stack(
            alignment: Alignment.center,
            children: <Widget>[
              Text('${day.day}', style: theme.textTheme.bodyMedium?.copyWith(color: text)),
              if (practice != null && practice.takes > 0)
                Positioned(
                  bottom: AppTheme.spacingTiny,
                  child: Container(
                    width: _takeDotSize,
                    height: _takeDotSize,
                    decoration: BoxDecoration(color: colors.error, shape: BoxShape.circle),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  void _onTap() => onSelected(day);
}
