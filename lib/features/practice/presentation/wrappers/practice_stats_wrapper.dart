import 'package:flutter/material.dart';
import 'package:watch_it/watch_it.dart';

import '../../../recordings/domain/entities/recording.dart';
import '../../../recordings/presentation/di/recordings_getters.dart';
import '../../../song/domain/entities/song.dart';
import '../../../song/presentation/di/song_getters.dart';
import '../../domain/entities/practice_session.dart';
import '../../domain/entities/practice_stats.dart';
import '../controllers/practice_page_controller.dart';
import '../di/practice_getters.dart';
import '../widgets/practice_stats_widget.dart';
import '../widgets/practice_time_text_widget.dart';

/// Counts the practice from the sessions, the takes and the songs and gives the statistics to [PracticeStatsWidget]
/// with the calendar position of the page's [PracticePageController].
final class PracticeStatsWrapper extends WatchingWidget {
  static const String _titleSeparator = ' — ';

  /// The calendar position, owned by the page.
  final PracticePageController practicePageController;

  /// The texts.
  final PracticeTexts texts;

  /// Opens a song (tapping it in a list).
  final ValueChanged<Song> onSongPressed;

  /// Creates the wrapper.
  const PracticeStatsWrapper({
    required this.practicePageController,
    required this.texts,
    required this.onSongPressed,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final List<PracticeSession> sessions = watch(watchPracticeSessionsUseCase()).value;
    final List<Recording> recordings = watch(watchRecordingsUseCase()).value;
    final List<Song> songs = watch(watchListOfSongsUseCase()).value;
    final DateTime month = watch(practicePageController.monthController).value;
    final DateTime selectedDay = watch(practicePageController.selectedDayController).value;

    final DateTime now = DateTime.now();
    final PracticeStats stats = calculatePracticeStatsUseCase(sessions: sessions, recordings: recordings, now: now);
    Song? songOf(String songId) => songs.where((Song song) => song.id == songId).firstOrNull;

    return PracticeStatsWidget(
      stats: stats,
      month: month,
      selectedDay: selectedDay,
      today: PracticeStats.dayOf(now),
      titleOf: (String songId) => _titleOf(songOf(songId)),
      onPressedOf: (String songId) => _pressedOf(songOf(songId)),
      texts: texts,
      onDaySelected: practicePageController.selectDay,
      onPreviousMonth: practicePageController.showPreviousMonth,
      onNextMonth: practicePageController.showNextMonth,
    );
  }

  String _titleOf(Song? song) => song == null ? texts.songDeletedText : '${song.author}$_titleSeparator${song.name}';

  VoidCallback? _pressedOf(Song? song) => song == null ? null : () => onSongPressed(song);
}
