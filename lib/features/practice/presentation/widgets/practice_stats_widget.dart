import 'package:flutter/material.dart';
import 'package:watch_it/watch_it.dart';

import '../../../../core/presentation/l10n/app_translations.dart';
import '../../../../core/presentation/theme.dart';
import '../../../recordings/domain/entities/recording.dart';
import '../../../recordings/presentation/di/recordings_getters.dart';
import '../../../song/domain/entities/song.dart';
import '../../../song/presentation/di/song_getters.dart';
import '../../domain/entities/practice_day.dart';
import '../../domain/entities/practice_session.dart';
import '../../domain/entities/practice_stats.dart';
import '../../domain/entities/song_practice.dart';
import '../controllers/practice_page_controller.dart';
import '../di/practice_getters.dart';
import 'practice_calendar_widget.dart';
import 'practice_summary_widget.dart';
import 'practice_time_text_widget.dart';
import 'song_practice_list_widget.dart';

/// Practice statistics: totals and streaks, a calendar with the days of practice, the songs of
/// the chosen day and the most practised songs.
final class PracticeStatsWidget extends WatchingWidget {
  static const String _titleSeparator = ' — ';
  static const String _dayTitleSeparator = ': ';
  static const String _dateSeparator = '.';
  static const String _zero = '0';

  /// Opens a song (tapping it in a list).
  final void Function(Song song) onSongPressed;

  /// Creates a new [PracticeStatsWidget].
  const PracticeStatsWidget({super.key, required this.onSongPressed});

  @override
  Widget build(BuildContext context) {
    final Translations t = context.t;
    final PracticePageController practicePageController = createOnce(
      _createPracticePageController,
      dispose: _disposePracticePageController,
    );
    final List<PracticeSession> sessions = watch(watchPracticeSessionsUseCase()).value;
    final List<Recording> recordings = watch(watchRecordingsUseCase()).value;
    final List<Song> songs = watch(watchListOfSongsUseCase()).value;
    final DateTime month = watch(practicePageController.monthController).value;
    final DateTime selectedDay = watch(practicePageController.selectedDayController).value;

    final DateTime now = DateTime.now();
    final PracticeStats stats = calculatePracticeStatsUseCase(sessions: sessions, recordings: recordings, now: now);
    final Map<String, String> titles = <String, String>{
      for (final Song song in songs) song.id: '${song.author}$_titleSeparator${song.name}',
    };
    final Map<String, Song> songsById = <String, Song>{for (final Song song in songs) song.id: song};
    VoidCallback? pressedOf(String songId) => _pressedOf(songsById[songId]);
    final PracticeDay? day = stats.days[selectedDay];
    final ThemeData theme = Theme.of(context);

    return ListView(
      padding: const EdgeInsets.all(AppTheme.spacingMedium),
      children: <Widget>[
        PracticeSummaryWidget(stats: stats),
        const SizedBox(height: AppTheme.spacingMedium),
        Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: AppTheme.maxContentWidth),
            child: PracticeCalendarWidget(
              month: month,
              selectedDay: selectedDay,
              today: PracticeStats.dayOf(now),
              days: stats.days,
              onDaySelected: practicePageController.selectDay,
              onPreviousMonth: practicePageController.showPreviousMonth,
              onNextMonth: practicePageController.showNextMonth,
            ),
          ),
        ),
        const SizedBox(height: AppTheme.spacingMedium),
        Text(
          '${_formatDate(selectedDay)}$_dayTitleSeparator${PracticeTimeTextWidget.format(t, day?.time ?? Duration.zero)}',
          style: theme.textTheme.titleMedium,
        ),
        SongPracticeListWidget(
          songs: day?.songs ?? const <SongPractice>[],
          titleOf: (String songId) => titles[songId] ?? t.common.songDeleted,
          onPressedOf: pressedOf,
          emptyText: t.practice.noPracticeThisDay,
        ),
        const SizedBox(height: AppTheme.spacingMedium),
        Text(t.practice.topSongs, style: theme.textTheme.titleMedium),
        SongPracticeListWidget(
          songs: stats.topSongs,
          titleOf: (String songId) => titles[songId] ?? t.common.songDeleted,
          onPressedOf: pressedOf,
          emptyText: t.practice.noPracticeYet,
        ),
      ],
    );
  }

  VoidCallback? _pressedOf(Song? song) => song == null ? null : () => onSongPressed(song);

  static PracticePageController _createPracticePageController() => PracticePageController(today: DateTime.now());

  static void _disposePracticePageController(PracticePageController practicePageController) =>
      practicePageController.dispose();

  static String _formatDate(DateTime day) {
    final String date = day.day.toString().padLeft(AppTheme.twoDigits, _zero);
    final String month = day.month.toString().padLeft(AppTheme.twoDigits, _zero);
    return '$date$_dateSeparator$month$_dateSeparator${day.year}';
  }
}
