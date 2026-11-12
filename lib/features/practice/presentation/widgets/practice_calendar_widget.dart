import 'package:flutter/material.dart';

import '../../../../core/presentation/theme.dart';
import '../../domain/entities/practice_day.dart';
import 'practice_day_cell_widget.dart';

/// Month calendar with a mark on every day of practice ([PracticeDayCellWidget]); weeks start
/// on Monday.
final class PracticeCalendarWidget extends StatelessWidget {
  static const List<String> _monthNames = <String>[
    'Січень',
    'Лютий',
    'Березень',
    'Квітень',
    'Травень',
    'Червень',
    'Липень',
    'Серпень',
    'Вересень',
    'Жовтень',
    'Листопад',
    'Грудень',
  ];
  static const List<String> _weekdayNames = <String>['Пн', 'Вт', 'Ср', 'Чт', 'Пт', 'Сб', 'Нд'];
  static const String _previousLabel = 'Попередній місяць';
  static const String _nextLabel = 'Наступний місяць';
  static const String _space = ' ';
  static const int _daysPerWeek = 7;

  /// First day of the month shown.
  final DateTime month;

  /// The chosen day.
  final DateTime selectedDay;

  /// Today (midnight).
  final DateTime today;

  /// Days with practice, by midnight.
  final Map<DateTime, PracticeDay> days;

  /// Called with the tapped day.
  final ValueChanged<DateTime> onDaySelected;

  /// Called by the "previous month" button.
  final VoidCallback onPreviousMonth;

  /// Called by the "next month" button.
  final VoidCallback onNextMonth;

  /// Creates a new [PracticeCalendarWidget].
  const PracticeCalendarWidget({
    super.key,
    required this.month,
    required this.selectedDay,
    required this.today,
    required this.days,
    required this.onDaySelected,
    required this.onPreviousMonth,
    required this.onNextMonth,
  });

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final int leading = month.weekday - DateTime.monday;
    final int length = DateTime(month.year, month.month + 1, 0).day;
    final int cells = ((leading + length) / _daysPerWeek).ceil() * _daysPerWeek;

    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.spacingSmall),
        child: Column(
          children: <Widget>[
            Row(
              children: <Widget>[
                IconButton(tooltip: _previousLabel, onPressed: onPreviousMonth, icon: const Icon(Icons.chevron_left)),
                Expanded(
                  child: Text(
                    '${_monthNames[month.month - 1]}$_space${month.year}',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.titleMedium,
                  ),
                ),
                IconButton(tooltip: _nextLabel, onPressed: onNextMonth, icon: const Icon(Icons.chevron_right)),
              ],
            ),
            Row(
              children: <Widget>[
                for (final String name in _weekdayNames)
                  Expanded(
                    child: Text(
                      name,
                      textAlign: TextAlign.center,
                      style: theme.textTheme.labelSmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: AppTheme.spacingTiny),
            GridView.count(
              crossAxisCount: _daysPerWeek,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              children: <Widget>[
                for (int cell = 0; cell < cells; cell++)
                  cell < leading || cell >= leading + length
                      ? const SizedBox.shrink()
                      : _cell(DateTime(month.year, month.month, cell - leading + 1)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  PracticeDayCellWidget _cell(DateTime day) => PracticeDayCellWidget(
    day: day,
    practice: days[day],
    isSelected: day == selectedDay,
    isToday: day == today,
    onSelected: onDaySelected,
  );
}
