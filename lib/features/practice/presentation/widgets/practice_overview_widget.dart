import '../../../../core/presentation/widgets/surface_widget.dart';
import 'package:flutter/material.dart';

import '../../../../core/presentation/theme.dart';
import '../../domain/entities/practice_stats.dart';
import 'practice_time_text_widget.dart';

/// Short practice overview for the top of the home page: today, this week, the streak and the
/// covers, plus the days of this week marked. A tap opens the full statistics.
final class PracticeOverviewWidget extends StatelessWidget {
  static const double _dayMarkSize = 26;

  /// The narrowest "All statistics" beside the days; on a narrower card it goes under them.
  static const double _allStatsMinWidth = 96;

  /// The stats.
  final PracticeStats stats;

  /// Today (midnight).
  final DateTime today;

  /// Called by a tap on the overview.
  final VoidCallback onOpenPressed;

  /// The texts.
  final PracticeTexts texts;

  /// Creates a new [PracticeOverviewWidget].
  const PracticeOverviewWidget({
    super.key,
    required this.stats,
    required this.today,
    required this.onOpenPressed,
    required this.texts,
  });

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme colors = theme.colorScheme;
    final DateTime monday = DateTime(today.year, today.month, today.day - (today.weekday - DateTime.monday));

    return SurfaceWidget(
      margin: EdgeInsets.zero,
      child: InkWell(
        borderRadius: BorderRadius.circular(AppTheme.radius),
        onTap: onOpenPressed,
        child: Padding(
          padding: const EdgeInsets.all(AppTheme.spacingMedium),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Row(
                children: <Widget>[
                  _StatWidget(
                    label: texts.todayLabel,
                    value: texts.timeText(stats.dayOn(today)?.time ?? Duration.zero),
                  ),
                  _StatWidget(label: texts.weekLabel, value: texts.timeText(stats.weekTime)),
                  _StatWidget(label: texts.streakLabel, value: texts.daysText(stats.currentStreak)),
                  _StatWidget(label: texts.coversLabel, value: '${stats.totalTakes}'),
                ],
              ),
              const SizedBox(height: AppTheme.spacingSmall),
              LayoutBuilder(
                builder: (BuildContext context, BoxConstraints constraints) {
                  final List<Widget> days = <Widget>[
                    for (int index = 0; index < texts.weekdayLetters.length; index++)
                      Padding(
                        padding: const EdgeInsets.only(right: AppTheme.spacingTiny),
                        child: _DayMarkWidget(
                          letter: texts.weekdayLetters[index],
                          practised: stats.practisedOn(DateTime(monday.year, monday.month, monday.day + index)),
                          isToday: index == today.weekday - DateTime.monday,
                          size: _dayMarkSize,
                          colors: colors,
                          style: theme.textTheme.labelSmall,
                        ),
                      ),
                  ];
                  final Widget allStats = Row(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      Flexible(
                        child: Text(
                          texts.allStatsLabel,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.end,
                          style: theme.textTheme.labelMedium?.copyWith(color: colors.primary),
                        ),
                      ),
                      Icon(Icons.chevron_right, color: colors.primary),
                    ],
                  );
                  final double daysWidth = texts.weekdayLetters.length * (_dayMarkSize + AppTheme.spacingTiny);
                  if (constraints.maxWidth - daysWidth >= _allStatsMinWidth) {
                    return Row(
                      children: <Widget>[
                        ...days,
                        Expanded(
                          child: Align(alignment: Alignment.centerRight, child: allStats),
                        ),
                      ],
                    );
                  }
                  // A narrow phone: the days fill the line, "All statistics" goes under them.
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: <Widget>[
                      Row(children: days),
                      const SizedBox(height: AppTheme.spacingTiny),
                      Align(alignment: Alignment.centerRight, child: allStats),
                    ],
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// One number with its label.
final class _StatWidget extends StatelessWidget {
  final String label;
  final String value;

  const _StatWidget({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    // A long value ("20 h 43 min") gets smaller instead of cut, with a gap to the next one.
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.only(right: AppTheme.spacingSmall),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.labelSmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
            ),
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(value, maxLines: 1, style: theme.textTheme.titleMedium),
            ),
          ],
        ),
      ),
    );
  }
}

/// A weekday of this week: filled when practised, ringed when today.
final class _DayMarkWidget extends StatelessWidget {
  final String letter;
  final bool practised;
  final bool isToday;
  final double size;
  final ColorScheme colors;
  final TextStyle? style;

  const _DayMarkWidget({
    required this.letter,
    required this.practised,
    required this.isToday,
    required this.size,
    required this.colors,
    required this.style,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: practised ? colors.primary : colors.surfaceContainerHighest,
        border: isToday ? Border.all(color: colors.tertiary, width: 2) : null,
      ),
      child: Text(letter, style: style?.copyWith(color: practised ? colors.onPrimary : colors.onSurfaceVariant)),
    );
  }
}
