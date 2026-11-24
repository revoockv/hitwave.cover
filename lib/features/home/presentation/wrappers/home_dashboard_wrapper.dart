import 'package:flutter/material.dart';
import 'package:watch_it/watch_it.dart';

import '../../../../core/presentation/l10n/app_translations.dart';
import '../../../history/domain/entities/usage_history.dart';
import '../../../history/presentation/di/history_getters.dart';
import '../../../practice/domain/entities/practice_session.dart';
import '../../../practice/domain/entities/practice_stats.dart';
import '../../../practice/presentation/di/practice_getters.dart';
import '../../../practice/presentation/l10n/practice_texts.dart';
import '../../../recordings/domain/entities/cover_counts.dart';
import '../../../recordings/domain/entities/recording.dart';
import '../../../recordings/domain/entities/shared_song.dart';
import '../../../recordings/presentation/di/recordings_getters.dart';
import '../../../recordings/presentation/pages/recordings_list_page.dart';
import '../../../song/domain/entities/song.dart';
import '../../../song/presentation/l10n/song_widget_texts.dart';
import '../../domain/entities/recent_activity.dart';
import '../di/home_getters.dart';
import '../widgets/home_dashboard_widget.dart';

/// The home tab: gives [HomeDashboardWidget] the stats, the recent songs and the recent covers. Watches the practice,
/// the covers and the history, so a change of them rebuilds only this tab.
final class HomeDashboardWrapper extends WatchingWidget {
  static const String _titleSeparator = ' — ';

  /// All the songs.
  final List<Song> songs;

  /// Opens the statistics tab.
  final VoidCallback onStatsPressed;

  /// Opens the songs tab.
  final VoidCallback onAllSongsPressed;

  /// Opens the covers tab.
  final VoidCallback onAllCoversPressed;

  /// Called when a song is tapped.
  final ValueChanged<Song> onSongTap;

  /// Called when "edit" is chosen for a song.
  final ValueChanged<Song> onSongEdit;

  /// Called when "delete" is chosen for a song.
  final ValueChanged<Song> onSongDelete;

  /// Creates the wrapper.
  const HomeDashboardWrapper({
    super.key,
    required this.songs,
    required this.onStatsPressed,
    required this.onAllSongsPressed,
    required this.onAllCoversPressed,
    required this.onSongTap,
    required this.onSongEdit,
    required this.onSongDelete,
  });

  @override
  Widget build(BuildContext context) {
    final Translations t = context.t;
    final List<PracticeSession> sessions = watch(watchPracticeSessionsUseCase()).value;
    final List<Recording> recordings = watch(watchRecordingsUseCase()).value;
    final UsageHistory history = watch(watchUsageHistoryUseCase()).value;
    final Map<String, Song> songsById = <String, Song>{for (final Song song in songs) song.id: song};
    final DateTime now = DateTime.now();
    final RecentActivity recent = findRecentActivityUseCase(songs: songs, recordings: recordings, history: history);

    return HomeDashboardWidget(
      stats: calculatePracticeStatsUseCase(sessions: sessions, recordings: recordings, now: now),
      today: PracticeStats.dayOf(now),
      recentSongs: recent.songs,
      recentCoversList: recent.covers.isEmpty
          ? null
          : RecordingsListPage(
              recordings: recent.covers,
              emptyText: t.song.noRecentCovers,
              headerOf: (Recording recording) => _songTitle(t, songsById[recording.songId]),
              onHeaderPressedOf: (Recording recording) => _openerOf(songsById[recording.songId]),
              songOf: (Recording recording) => _sharedSong(songsById[recording.songId]),
              shrinkWrap: true,
            ),
      coverCountOf: CoverCounts.fromRecordings(recordings).of,
      texts: HomeDashboardTexts(
        recentSongsTitle: t.song.recentlyOpened,
        recentCoversTitle: t.song.recentlyPlayed,
        allLabel: t.song.all,
        noRecentSongsText: t.song.noRecentSongs,
        noRecentCoversText: t.song.noRecentCovers,
        practice: t.practiceTexts,
        songTile: t.songTile,
      ),
      onStatsPressed: onStatsPressed,
      onAllSongsPressed: onAllSongsPressed,
      onAllCoversPressed: onAllCoversPressed,
      onSongTap: onSongTap,
      onSongEdit: onSongEdit,
      onSongDelete: onSongDelete,
    );
  }

  /// Opens the lyrics of [song]; `null` when the song is gone.
  VoidCallback? _openerOf(Song? song) => song == null ? null : () => onSongTap(song);

  static SharedSong? _sharedSong(Song? song) => song == null ? null : SharedSong(author: song.author, name: song.name);

  static String _songTitle(Translations t, Song? song) =>
      song == null ? t.common.songDeleted : '${song.author}$_titleSeparator${song.name}';
}
