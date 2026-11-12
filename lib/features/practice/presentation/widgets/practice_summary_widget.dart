import 'package:flutter/material.dart';

import '../../../../core/presentation/theme.dart';
import '../../domain/entities/practice_stats.dart';
import 'practice_time_text_widget.dart';

/// Tiles with the totals and the streaks of the practice.
final class PracticeSummaryWidget extends StatelessWidget {
  static const String _week = 'Цей тиждень';
  static const String _month = 'Цей місяць';
  static const String _total = 'Усього';
  static const String _streak = 'Серія днів';
  static const String _takes = 'Записів';
  static const String _daysSuffix = ' дн.';
  static const String _sessionsSuffix = ' занять';
  static const String _longestPrefix = 'найдовша ';
  static const String _separator = ' · ';
  static const double _tileMinWidth = 150;

  /// The stats.
  final PracticeStats stats;

  /// Creates a new [PracticeSummaryWidget].
  const PracticeSummaryWidget({super.key, required this.stats});

  @override
  Widget build(BuildContext context) {
    final List<_TileData> tiles = <_TileData>[
      _TileData(_week, PracticeTimeTextWidget.format(stats.weekTime), '${stats.weekDays}$_daysSuffix'),
      _TileData(_month, PracticeTimeTextWidget.format(stats.monthTime), '${stats.monthDays}$_daysSuffix'),
      _TileData(
        _total,
        PracticeTimeTextWidget.format(stats.totalTime),
        '${stats.totalSessions}$_sessionsSuffix$_separator${stats.days.length}$_daysSuffix',
      ),
      _TileData(_streak, '${stats.currentStreak}$_daysSuffix', '$_longestPrefix${stats.longestStreak}$_daysSuffix'),
      _TileData(_takes, '${stats.totalTakes}', null),
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
    return Card(
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
