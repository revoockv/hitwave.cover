import '../../../../core/presentation/l10n/app_translations.dart';
import '../../../../core/presentation/theme.dart';
import '../../domain/entities/practice_failure.dart';
import '../widgets/practice_time_text_widget.dart';

/// The text of a [PracticeFailure] shown to the user.
extension PracticeFailureText on PracticeFailure {
  /// The text of this failure in the language of [t].
  String text(Translations t) => switch (this) {
    PracticeFailure.saveSession => t.practice.saveFailed,
    PracticeFailure.importSessions => t.practice.importFailed,
    PracticeFailure.deleteSession => t.practice.deleteFailed,
    PracticeFailure.clear => t.practice.clearFailed,
  };
}

/// The texts of the practice widgets in the language of these [Translations].
extension PracticeWidgetTexts on Translations {
  static const String _none = '—';
  static const String _zero = '0';
  static const int _minutesPerHour = 60;

  /// The texts of every practice widget.
  PracticeTexts get practiceTexts => PracticeTexts(
    timeText: _time,
    daysText: _days,
    sessionsText: _sessions,
    takesText: _takes,
    longestText: _longest,
    thisWeekLabel: practice.thisWeek,
    thisMonthLabel: practice.thisMonth,
    totalLabel: practice.total,
    dayStreakLabel: practice.dayStreak,
    takesLabel: practice.takes,
    todayLabel: practice.today,
    weekLabel: practice.week,
    streakLabel: practice.streak,
    coversLabel: practice.covers,
    allStatsLabel: practice.allStats,
    weekdayLetters: practice.weekdayLetters,
    weekdayNames: practice.weekdayNames,
    monthNames: practice.monthNames,
    previousMonthTooltip: practice.previousMonth,
    nextMonthTooltip: practice.nextMonth,
    noPracticeThisDayText: practice.noPracticeThisDay,
    noPracticeYetText: practice.noPracticeYet,
    topSongsTitle: practice.topSongs,
    songDeletedText: common.songDeleted,
    filterAllLabel: practice.filterAll,
    filterPracticeOnlyLabel: practice.filterPracticeOnly,
    filterWithTakesLabel: practice.filterWithTakes,
    nothingFoundText: common.nothingFound,
    noCoversText: recordings.noCovers,
    deleteTooltip: common.delete,
    deleteTitle: practice.deleteTitle,
    deleteMessage: practice.deleteMessage,
    deleteTakesLabel: _deleteTakes,
    cancelLabel: common.cancel,
    deleteLabel: common.delete,
  );

  String _time(Duration time) {
    if (time == Duration.zero) return _none;
    final int minutes = time.inMinutes;
    if (minutes == 0) return practice.lessThanMinute;
    if (minutes < _minutesPerHour) return practice.minutes(minutes: minutes);
    final String rest = (minutes % _minutesPerHour).toString().padLeft(AppTheme.twoDigits, _zero);
    return practice.hoursMinutes(hours: time.inHours, minutes: rest);
  }

  String _days(int count) => practice.days(n: count);

  String _sessions(int count) => practice.sessions(n: count);

  String _takes(int count) => practice.takesCount(n: count);

  String _longest(String days) => practice.longest(value: days);

  String _deleteTakes(int count) => practice.deleteTakes(n: count);
}
