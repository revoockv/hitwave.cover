import 'package:flutter/material.dart';

/// The texts of the practice widgets: labels, names of months and weekdays, and how times and counts are written.
final class PracticeTexts {
  /// A practice time as text ("—", "< 1 min", "25 min", "1 h 05 min").
  final String Function(Duration time) timeText;

  /// A number of days ("3 days").
  final String Function(int count) daysText;

  /// A number of sessions ("12 sessions").
  final String Function(int count) sessionsText;

  /// A number of takes ("2 takes").
  final String Function(int count) takesText;

  /// The longest streak ("longest: 9 days").
  final String Function(String days) longestText;

  /// Label of this week's time.
  final String thisWeekLabel;

  /// Label of this month's time.
  final String thisMonthLabel;

  /// Label of the total time.
  final String totalLabel;

  /// Label of the streak of days.
  final String dayStreakLabel;

  /// Label of the number of takes.
  final String takesLabel;

  /// Label of today's time in the overview.
  final String todayLabel;

  /// Label of the week's time in the overview.
  final String weekLabel;

  /// Label of the streak in the overview.
  final String streakLabel;

  /// Label of the covers in the overview.
  final String coversLabel;

  /// Link from the overview to the statistics.
  final String allStatsLabel;

  /// One letter per weekday, Monday first.
  final List<String> weekdayLetters;

  /// The short names of the weekdays, Monday first.
  final List<String> weekdayNames;

  /// The names of the months, January first.
  final List<String> monthNames;

  /// Tooltip of the previous month button.
  final String previousMonthTooltip;

  /// Tooltip of the next month button.
  final String nextMonthTooltip;

  /// Shown when the chosen day has no practice.
  final String noPracticeThisDayText;

  /// Shown when there is no practice at all.
  final String noPracticeYetText;

  /// Heading of the most practised songs.
  final String topSongsTitle;

  /// The title of a song that is gone.
  final String songDeletedText;

  /// Label of the filter that shows everything.
  final String filterAllLabel;

  /// Label of the filter that shows practice without takes.
  final String filterPracticeOnlyLabel;

  /// Label of the filter that shows practice with takes.
  final String filterWithTakesLabel;

  /// Shown when the search finds nothing.
  final String nothingFoundText;

  /// Shown when there are no covers.
  final String noCoversText;

  /// Tooltip of the delete button of a session.
  final String deleteTooltip;

  /// Title of the delete dialog.
  final String deleteTitle;

  /// What deleting a session does.
  final String deleteMessage;

  /// Label of the checkbox that deletes the takes too ("Delete 2 takes too").
  final String Function(int count) deleteTakesLabel;

  /// Label of the cancel button.
  final String cancelLabel;

  /// Label of the delete button.
  final String deleteLabel;

  /// Creates the texts.
  const PracticeTexts({
    required this.timeText,
    required this.daysText,
    required this.sessionsText,
    required this.takesText,
    required this.longestText,
    required this.thisWeekLabel,
    required this.thisMonthLabel,
    required this.totalLabel,
    required this.dayStreakLabel,
    required this.takesLabel,
    required this.todayLabel,
    required this.weekLabel,
    required this.streakLabel,
    required this.coversLabel,
    required this.allStatsLabel,
    required this.weekdayLetters,
    required this.weekdayNames,
    required this.monthNames,
    required this.previousMonthTooltip,
    required this.nextMonthTooltip,
    required this.noPracticeThisDayText,
    required this.noPracticeYetText,
    required this.topSongsTitle,
    required this.songDeletedText,
    required this.filterAllLabel,
    required this.filterPracticeOnlyLabel,
    required this.filterWithTakesLabel,
    required this.nothingFoundText,
    required this.noCoversText,
    required this.deleteTooltip,
    required this.deleteTitle,
    required this.deleteMessage,
    required this.deleteTakesLabel,
    required this.cancelLabel,
    required this.deleteLabel,
  });
}

/// A practice time as text. Dumb: the format comes with [texts].
final class PracticeTimeTextWidget extends StatelessWidget {
  /// The time.
  final Duration time;

  /// How times are written.
  final PracticeTexts texts;

  /// Style of the text.
  final TextStyle? style;

  /// Creates a new [PracticeTimeTextWidget].
  const PracticeTimeTextWidget({super.key, required this.time, required this.texts, this.style});

  @override
  Widget build(BuildContext context) {
    return Text(texts.timeText(time), style: style);
  }
}
