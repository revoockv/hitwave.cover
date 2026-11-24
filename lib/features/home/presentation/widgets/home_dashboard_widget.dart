import 'package:flutter/material.dart';
import '../../../recordings/domain/entities/cover_counts.dart';

import '../../../../core/presentation/l10n/app_translations.dart';
import '../../../../core/presentation/theme.dart';
import '../../../practice/domain/entities/practice_stats.dart';
import '../../../practice/presentation/widgets/practice_overview_widget.dart';
import '../../../recordings/domain/entities/recording.dart';
import '../../../recordings/domain/entities/shared_song.dart';
import '../../../recordings/presentation/widgets/recordings_list_widget.dart';
import '../../../song/domain/entities/song.dart';
import '../../../song/presentation/widgets/song_tile_widget.dart';

/// The home tab: the mini statistics, the songs opened last and the covers played last.
final class HomeDashboardWidget extends StatelessWidget {
  /// The practice stats.
  final PracticeStats stats;

  /// Today (midnight).
  final DateTime today;

  /// The songs opened last, newest first.
  final List<Song> recentSongs;

  /// The covers played last, newest first.
  final List<Recording> recentCovers;

  /// Number of covers by song id.
  final CoverCounts coverCounts;

  /// Title of the song of a cover.
  final String? Function(Recording recording) coverTitleOf;

  /// What tapping the song above a cover does (opens it), or `null` when it does nothing.
  final VoidCallback? Function(Recording recording) coverSongPressedOf;

  /// The song a shared cover is named after.
  final SharedSong? Function(Recording recording) coverSongOf;

  /// Opens the statistics tab.
  final VoidCallback onStatsPressed;

  /// Opens the songs tab.
  final VoidCallback onAllSongsPressed;

  /// Opens the covers tab.
  final VoidCallback onAllCoversPressed;

  /// Called when a song is tapped.
  final void Function(Song song) onSongTap;

  /// Called when "edit" is chosen for a song.
  final void Function(Song song) onSongEdit;

  /// Called when "delete" is chosen for a song.
  final void Function(Song song) onSongDelete;

  /// Creates a new [HomeDashboardWidget].
  const HomeDashboardWidget({
    super.key,
    required this.stats,
    required this.today,
    required this.recentSongs,
    required this.recentCovers,
    required this.coverCounts,
    required this.coverTitleOf,
    required this.coverSongPressedOf,
    required this.coverSongOf,
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
    final ThemeData theme = Theme.of(context);
    final TextStyle? hintStyle = theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant);

    final Widget overview = PracticeOverviewWidget(stats: stats, today: today, onOpenPressed: onStatsPressed);
    final List<Widget> songsSection = <Widget>[
      _SectionTitleWidget(title: t.song.recentlyOpened, actionLabel: t.song.all, onActionPressed: onAllSongsPressed),
      if (recentSongs.isEmpty)
        Text(t.song.noRecentSongs, style: hintStyle)
      else
        for (final Song song in recentSongs)
          SongTileWidget(
            song: song,
            onTap: onSongTap,
            onEdit: onSongEdit,
            onDelete: onSongDelete,
            coverCount: coverCounts.of(song.id),
          ),
    ];
    final List<Widget> coversSection = <Widget>[
      _SectionTitleWidget(title: t.song.recentlyPlayed, actionLabel: t.song.all, onActionPressed: onAllCoversPressed),
      if (recentCovers.isEmpty)
        Text(t.song.noRecentCovers, style: hintStyle)
      else
        RecordingsListWidget(
          recordings: recentCovers,
          emptyText: t.song.noRecentCovers,
          headerOf: coverTitleOf,
          onHeaderPressedOf: coverSongPressedOf,
          songOf: coverSongOf,
          shrinkWrap: true,
        ),
    ];

    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final double width = constraints.maxWidth;
        // A desktop window: the overview and the songs on the left, the covers on the right.
        if (width >= AppTheme.twoColumnBreakpoint) {
          return SingleChildScrollView(
            padding: AppTheme.centeredPadding(width, AppTheme.maxPageWidth, minimum: AppTheme.spacingLarge),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: <Widget>[
                      overview,
                      const SizedBox(height: AppTheme.spacingLarge),
                      ...songsSection,
                    ],
                  ),
                ),
                const SizedBox(width: AppTheme.spacingLarge),
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: coversSection),
                ),
              ],
            ),
          );
        }
        return ListView(
          padding: AppTheme.centeredPadding(width, AppTheme.maxContentWidth),
          children: <Widget>[
            overview,
            const SizedBox(height: AppTheme.spacingMedium),
            ...songsSection,
            const SizedBox(height: AppTheme.spacingMedium),
            ...coversSection,
          ],
        );
      },
    );
  }
}

/// A section title with a link to the full list.
final class _SectionTitleWidget extends StatelessWidget {
  final String title;
  final String actionLabel;
  final VoidCallback onActionPressed;

  const _SectionTitleWidget({required this.title, required this.actionLabel, required this.onActionPressed});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        Expanded(child: Text(title, style: Theme.of(context).textTheme.titleMedium)),
        TextButton(onPressed: onActionPressed, child: Text(actionLabel)),
      ],
    );
  }
}
