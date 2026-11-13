import '../../../recordings/domain/entities/recording.dart';
import 'practice_day.dart';
import 'practice_session.dart';
import 'song_practice.dart';

/// Totals, streaks and the calendar of the practice, made from the sessions and the takes.
final class PracticeStats {
  static const int _topSongCount = 5;

  /// Practice time of this week (from Monday).
  final Duration weekTime;

  /// Days with practice this week.
  final int weekDays;

  /// Practice time of this month.
  final Duration monthTime;

  /// Days with practice this month.
  final int monthDays;

  /// Practice time of all time.
  final Duration totalTime;

  /// Number of sessions of all time.
  final int totalSessions;

  /// Number of takes of all time.
  final int totalTakes;

  /// Days in a row with practice up to today (or up to yesterday while today has none yet).
  final int currentStreak;

  /// The longest run of days in a row with practice.
  final int longestStreak;

  /// Every day with practice or takes, by its midnight.
  final Map<DateTime, PracticeDay> days;

  /// The most practised songs of all time, longest first.
  final List<SongPractice> topSongs;

  /// Creates [PracticeStats].
  const PracticeStats({
    required this.weekTime,
    required this.weekDays,
    required this.monthTime,
    required this.monthDays,
    required this.totalTime,
    required this.totalSessions,
    required this.totalTakes,
    required this.currentStreak,
    required this.longestStreak,
    required this.days,
    required this.topSongs,
  });

  /// Counts [sessions] and [recordings] as of [now].
  factory PracticeStats.from({
    required List<PracticeSession> sessions,
    required List<Recording> recordings,
    required DateTime now,
  }) {
    final Map<DateTime, Map<String, _Tally>> byDay = <DateTime, Map<String, _Tally>>{};
    final Map<String, _Tally> bySong = <String, _Tally>{};
    for (final PracticeSession session in sessions) {
      byDay.putIfAbsent(dayOf(session.startedAt), _newSongTallies).putIfAbsent(session.songId, _Tally.new).time +=
          session.duration;
      bySong.putIfAbsent(session.songId, _Tally.new).time += session.duration;
    }
    for (final Recording recording in recordings) {
      byDay.putIfAbsent(dayOf(recording.recordedAt), _newSongTallies).putIfAbsent(recording.songId, _Tally.new).takes++;
      bySong.putIfAbsent(recording.songId, _Tally.new).takes++;
    }

    final Map<DateTime, PracticeDay> days = <DateTime, PracticeDay>{
      for (final MapEntry<DateTime, Map<String, _Tally>> entry in byDay.entries)
        entry.key: PracticeDay(
          day: entry.key,
          time: entry.value.values.fold(Duration.zero, _addTime),
          takes: entry.value.values.fold(0, _addTakes),
          songs: _ranked(entry.value),
        ),
    };

    final DateTime today = dayOf(now);
    final DateTime weekStart = today.subtract(Duration(days: today.weekday - DateTime.monday));
    final DateTime monthStart = DateTime(today.year, today.month);
    final Iterable<PracticeDay> week = days.values.where((PracticeDay day) => !day.day.isBefore(weekStart));
    final Iterable<PracticeDay> month = days.values.where((PracticeDay day) => !day.day.isBefore(monthStart));

    return PracticeStats(
      weekTime: week.fold(Duration.zero, _addDayTime),
      weekDays: week.length,
      monthTime: month.fold(Duration.zero, _addDayTime),
      monthDays: month.length,
      totalTime: sessions.fold(Duration.zero, _addSessionTime),
      totalSessions: sessions.length,
      totalTakes: recordings.length,
      currentStreak: _currentStreak(days.keys.toSet(), today),
      longestStreak: _longestStreak(days.keys.toList()),
      days: days,
      topSongs: _ranked(bySong).take(_topSongCount).toList(),
    );
  }

  /// Midnight of the day of [time], in local time.
  static DateTime dayOf(DateTime time) {
    final DateTime local = time.toLocal();
    return DateTime(local.year, local.month, local.day);
  }

  /// The day after [day] (safe over daylight saving changes).
  static DateTime nextDay(DateTime day) => DateTime(day.year, day.month, day.day + 1);

  static DateTime _previousDay(DateTime day) => DateTime(day.year, day.month, day.day - 1);

  static int _currentStreak(Set<DateTime> days, DateTime today) {
    DateTime day = days.contains(today) ? today : _previousDay(today);
    int streak = 0;
    while (days.contains(day)) {
      streak++;
      day = _previousDay(day);
    }
    return streak;
  }

  static int _longestStreak(List<DateTime> days) {
    days.sort();
    int longest = 0;
    int run = 0;
    DateTime? previous;
    for (final DateTime day in days) {
      run = previous != null && nextDay(previous) == day ? run + 1 : 1;
      if (run > longest) longest = run;
      previous = day;
    }
    return longest;
  }

  static List<SongPractice> _ranked(Map<String, _Tally> tallies) {
    final List<SongPractice> songs = <SongPractice>[
      for (final MapEntry<String, _Tally> entry in tallies.entries)
        SongPractice(songId: entry.key, time: entry.value.time, takes: entry.value.takes),
    ];
    songs.sort(_longerFirst);
    return songs;
  }

  static int _longerFirst(SongPractice a, SongPractice b) {
    final int byTime = b.time.compareTo(a.time);
    return byTime != 0 ? byTime : b.takes.compareTo(a.takes);
  }

  static Map<String, _Tally> _newSongTallies() => <String, _Tally>{};

  static Duration _addTime(Duration sum, _Tally tally) => sum + tally.time;

  static int _addTakes(int sum, _Tally tally) => sum + tally.takes;

  static Duration _addDayTime(Duration sum, PracticeDay day) => sum + day.time;

  static Duration _addSessionTime(Duration sum, PracticeSession session) => sum + session.duration;
}

/// Time and takes being added up.
final class _Tally {
  Duration time = Duration.zero;
  int takes = 0;
}
