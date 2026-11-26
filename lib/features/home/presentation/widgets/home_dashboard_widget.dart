import 'package:flutter/material.dart';

import '../../../../core/presentation/theme.dart';
import '../../../practice/domain/entities/practice_stats.dart';
import '../../../practice/presentation/widgets/practice_overview_widget.dart';
import '../../../practice/presentation/widgets/practice_time_text_widget.dart';
import '../../../song/domain/entities/song.dart';
import '../../../song/presentation/widgets/song_tile_widget.dart';

/// The texts of [HomeDashboardWidget].
final class HomeDashboardTexts {
  /// Title of the songs opened last.
  final String recentSongsTitle;

  /// Title of the covers played last.
  final String recentCoversTitle;

  /// Label of the links to the full lists.
  final String allLabel;

  /// Shown when no song was opened yet.
  final String noRecentSongsText;

  /// Shown when no cover was played yet.
  final String noRecentCoversText;

  /// The texts of the practice overview.
  final PracticeTexts practice;

  /// The texts of a song tile.
  final SongTileTexts songTile;

  /// Creates the texts.
  const HomeDashboardTexts({
    required this.recentSongsTitle,
    required this.recentCoversTitle,
    required this.allLabel,
    required this.noRecentSongsText,
    required this.noRecentCoversText,
    required this.practice,
    required this.songTile,
  });
}

/// The home tab: the mini statistics, the songs opened last and the covers played last.
///
/// Dumb: the stats, the songs, the texts and the list of covers ([recentCoversList], a page that owns the actions on
/// takes) come from above.
final class HomeDashboardWidget extends StatelessWidget {
  /// The practice stats.
  final PracticeStats stats;

  /// Today (midnight).
  final DateTime today;

  /// The songs opened last, newest first.
  final List<Song> recentSongs;

  /// The covers played last, or `null` when none was played yet.
  final Widget? recentCoversList;

  /// Number of covers of a song.
  final int Function(String songId) coverCountOf;

  /// The texts.
  final HomeDashboardTexts texts;

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
    required this.recentCoversList,
    required this.coverCountOf,
    required this.texts,
    required this.onStatsPressed,
    required this.onAllSongsPressed,
    required this.onAllCoversPressed,
    required this.onSongTap,
    required this.onSongEdit,
    required this.onSongDelete,
  });

  @override
  Widget build(BuildContext context) {
    final Widget? coversList = recentCoversList;
    final ThemeData theme = Theme.of(context);
    final TextStyle? hintStyle = theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant);

    final Widget overview = PracticeOverviewWidget(
      stats: stats,
      today: today,
      onOpenPressed: onStatsPressed,
      texts: texts.practice,
    );
    final List<Widget> songsSection = <Widget>[
      _SectionTitleWidget(
        title: texts.recentSongsTitle,
        actionLabel: texts.allLabel,
        onActionPressed: onAllSongsPressed,
      ),
      if (recentSongs.isEmpty)
        Text(texts.noRecentSongsText, style: hintStyle)
      else
        for (final Song song in recentSongs)
          SongTileWidget(
            song: song,
            onTap: onSongTap,
            onEdit: onSongEdit,
            onDelete: onSongDelete,
            coverCount: coverCountOf(song.id),
            texts: texts.songTile,
          ),
    ];
    final List<Widget> coversSection = <Widget>[
      _SectionTitleWidget(
        title: texts.recentCoversTitle,
        actionLabel: texts.allLabel,
        onActionPressed: onAllCoversPressed,
      ),
      coversList ?? Text(texts.noRecentCoversText, style: hintStyle),
    ];

    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final double width = constraints.maxWidth;
        // A desktop window: the overview and the songs on the left, the covers on the right.
        if (width >= AppTheme.twoColumnBreakpoint) {
          return SingleChildScrollView(
            padding: AppTheme.clearOfSystemBar(
              context,
              AppTheme.centeredPadding(width, AppTheme.maxPageWidth, minimum: AppTheme.spacingLarge),
            ),
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
          padding: AppTheme.clearOfSystemBar(context, AppTheme.centeredPadding(width, AppTheme.maxContentWidth)),
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
