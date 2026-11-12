import 'package:flutter/material.dart';

import '../../../../core/presentation/theme.dart';
import '../../../practice/domain/entities/practice_stats.dart';
import '../../../practice/presentation/widgets/practice_overview_widget.dart';
import '../../../recordings/domain/entities/recording.dart';
import '../../../recordings/presentation/widgets/recordings_list_widget.dart';
import '../../domain/entities/song.dart';
import 'song_tile_widget.dart';

/// The home tab: the mini statistics, the songs opened last and the covers played last.
final class HomeDashboardWidget extends StatelessWidget {
  static const String _recentSongsTitle = 'Нещодавно відкриті';
  static const String _recentCoversTitle = 'Нещодавно зіграні кавери';
  static const String _allLabel = 'Усі';
  static const String _noSongs = 'Відкрийте пісню — вона з’явиться тут.';
  static const String _noCovers = 'Послухайте свій кавер — він з’явиться тут.';

  /// The practice stats.
  final PracticeStats stats;

  /// Today (midnight).
  final DateTime today;

  /// The songs opened last, newest first.
  final List<Song> recentSongs;

  /// The covers played last, newest first.
  final List<Recording> recentCovers;

  /// Number of covers by song id.
  final Map<String, int> coverCounts;

  /// Title of the song of a cover.
  final String? Function(Recording recording) coverTitleOf;

  /// `Artist-Song` of a cover, the name it is shared under.
  final String? Function(Recording recording) coverShareNameOf;

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
    required this.coverShareNameOf,
    required this.onStatsPressed,
    required this.onAllSongsPressed,
    required this.onAllCoversPressed,
    required this.onSongTap,
    required this.onSongEdit,
    required this.onSongDelete,
  });

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final TextStyle? hintStyle = theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant);

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: AppTheme.maxContentWidth),
        child: ListView(
          padding: const EdgeInsets.all(AppTheme.spacingMedium),
          children: <Widget>[
            PracticeOverviewWidget(stats: stats, today: today, onOpenPressed: onStatsPressed),
            const SizedBox(height: AppTheme.spacingMedium),
            _SectionTitleWidget(title: _recentSongsTitle, actionLabel: _allLabel, onActionPressed: onAllSongsPressed),
            if (recentSongs.isEmpty)
              Text(_noSongs, style: hintStyle)
            else
              for (final Song song in recentSongs)
                SongTileWidget(
                  song: song,
                  onTap: onSongTap,
                  onEdit: onSongEdit,
                  onDelete: onSongDelete,
                  coverCount: coverCounts[song.id] ?? 0,
                ),
            const SizedBox(height: AppTheme.spacingMedium),
            _SectionTitleWidget(title: _recentCoversTitle, actionLabel: _allLabel, onActionPressed: onAllCoversPressed),
            if (recentCovers.isEmpty)
              Text(_noCovers, style: hintStyle)
            else
              RecordingsListWidget(
                recordings: recentCovers,
                emptyText: _noCovers,
                headerOf: coverTitleOf,
                shareNameOf: coverShareNameOf,
                shrinkWrap: true,
              ),
          ],
        ),
      ),
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
