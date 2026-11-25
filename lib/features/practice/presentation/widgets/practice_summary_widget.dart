import '../../../../core/presentation/widgets/surface_widget.dart';
import 'package:flutter/material.dart';

import '../../../../core/presentation/theme.dart';
import '../../domain/entities/practice_stats.dart';
import 'practice_time_text_widget.dart';

/// Tiles with the totals and the streaks of the practice.
final class PracticeSummaryWidget extends StatelessWidget {
  static const String _separator = ' · ';
  static const double _tileMinWidth = 150;

  /// The stats.
  final PracticeStats stats;

  /// The texts.
  final PracticeTexts texts;

  /// Creates a new [PracticeSummaryWidget].
  const PracticeSummaryWidget({super.key, required this.stats, required this.texts});

  @override
  Widget build(BuildContext context) {
    final List<_TileData> tiles = <_TileData>[
      _TileData(texts.thisWeekLabel, texts.timeText(stats.weekTime), texts.daysText(stats.weekDays)),
      _TileData(texts.thisMonthLabel, texts.timeText(stats.monthTime), texts.daysText(stats.monthDays)),
      _TileData(
        texts.totalLabel,
        texts.timeText(stats.totalTime),
        '${texts.sessionsText(stats.totalSessions)}$_separator${texts.daysText(stats.days.length)}',
      ),
      _TileData(
        texts.dayStreakLabel,
        texts.daysText(stats.currentStreak),
        texts.longestText(texts.daysText(stats.longestStreak)),
      ),
      _TileData(texts.takesLabel, '${stats.totalTakes}', null),
    ];
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final int columns = (constraints.maxWidth / _tileMinWidth).floor().clamp(1, tiles.length);
        final double width = (constraints.maxWidth - AppTheme.spacingSmall * (columns - 1)) / columns;
        return Wrap(
          spacing: AppTheme.spacingSmall,
          runSpacing: AppTheme.spacingSmall,
          children: <Widget>[
            for (final _TileData tile in tiles)
              SizedBox(
                width: width,
                child: _SummaryTileWidget(data: tile),
              ),
          ],
        );
      },
    );
  }
}

/// Texts of one tile.
final class _TileData {
  final String label;
  final String value;
  final String? detail;

  const _TileData(this.label, this.value, this.detail);
}

/// One tile: label, big value, small detail.
final class _SummaryTileWidget extends StatelessWidget {
  final _TileData data;

  const _SummaryTileWidget({required this.data});

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final String? detail = data.detail;
    return SurfaceWidget(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.spacingMedium),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(data.label, style: theme.textTheme.labelMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
            const SizedBox(height: AppTheme.spacingTiny),
            Text(data.value, style: theme.textTheme.titleLarge),
            if (detail != null)
              Text(detail, style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
          ],
        ),
      ),
    );
  }
}
