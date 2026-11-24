import 'package:flutter/material.dart';

import '../../../../core/presentation/theme.dart';
import '../../domain/entities/practice_day.dart';
import '../../domain/entities/practice_stats.dart';
import '../../domain/entities/song_practice.dart';
import 'practice_calendar_widget.dart';
import 'practice_summary_widget.dart';
import 'practice_time_text_widget.dart';
import 'song_practice_list_widget.dart';

/// Practice statistics: totals and streaks, a calendar with the days of practice, the songs of the chosen day and
/// the most practised songs.
///
/// Dumb: the counted statistics, the calendar position, the titles of the songs and the callbacks come from above.
final class PracticeStatsWidget extends StatelessWidget {
  static const String _dayTitleSeparator = ': ';
  static const String _dateSeparator = '.';
  static const String _zero = '0';

  /// The statistics.
  final PracticeStats stats;

  /// First day of the month the calendar shows.
  final DateTime month;

  /// The chosen day.
  final DateTime selectedDay;

  /// Today (midnight).
  final DateTime today;

  /// The title of a song by its id ("Artist — Song").
  final String Function(String songId) titleOf;

  /// What tapping a song does, or `null` when the song is gone.
  final VoidCallback? Function(String songId) onPressedOf;

  /// The texts.
  final PracticeTexts texts;

  /// Called with the day tapped in the calendar.
  final ValueChanged<DateTime> onDaySelected;

  /// Called by the previous month button.
  final VoidCallback onPreviousMonth;

  /// Called by the next month button.
  final VoidCallback onNextMonth;

  /// Creates a new [PracticeStatsWidget].
  const PracticeStatsWidget({
    super.key,
    required this.stats,
    required this.month,
    required this.selectedDay,
    required this.today,
    required this.titleOf,
    required this.onPressedOf,
    required this.texts,
    required this.onDaySelected,
    required this.onPreviousMonth,
    required this.onNextMonth,
  });

  @override
  Widget build(BuildContext context) {
    final PracticeDay? day = stats.dayOn(selectedDay);
    final ThemeData theme = Theme.of(context);

    return ListView(
      padding: const EdgeInsets.all(AppTheme.spacingMedium),
      children: <Widget>[
        PracticeSummaryWidget(stats: stats, texts: texts),
        const SizedBox(height: AppTheme.spacingMedium),
        Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: AppTheme.maxContentWidth),
            child: PracticeCalendarWidget(
              month: month,
              selectedDay: selectedDay,
              today: today,
              stats: stats,
              texts: texts,
              onDaySelected: onDaySelected,
              onPreviousMonth: onPreviousMonth,
              onNextMonth: onNextMonth,
            ),
          ),
        ),
        const SizedBox(height: AppTheme.spacingMedium),
        Text(
          '${_formatDate(selectedDay)}$_dayTitleSeparator${texts.timeText(day?.time ?? Duration.zero)}',
          style: theme.textTheme.titleMedium,
        ),
        SongPracticeListWidget(
          songs: day?.songs ?? const <SongPractice>[],
          titleOf: titleOf,
          onPressedOf: onPressedOf,
          emptyText: texts.noPracticeThisDayText,
          texts: texts,
        ),
        const SizedBox(height: AppTheme.spacingMedium),
        Text(texts.topSongsTitle, style: theme.textTheme.titleMedium),
        SongPracticeListWidget(
          songs: stats.topSongs,
          titleOf: titleOf,
          onPressedOf: onPressedOf,
          emptyText: texts.noPracticeYetText,
          texts: texts,
        ),
      ],
    );
  }

  static String _formatDate(DateTime day) {
    final String date = day.day.toString().padLeft(AppTheme.twoDigits, _zero);
    final String month = day.month.toString().padLeft(AppTheme.twoDigits, _zero);
    return '$date$_dateSeparator$month$_dateSeparator${day.year}';
  }
}
