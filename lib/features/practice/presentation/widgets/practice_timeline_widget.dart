import 'package:flutter/material.dart';

import '../../../../core/presentation/theme.dart';
import '../../domain/entities/practice_entry.dart';
import '../../domain/entities/practice_entry_filter.dart';
import 'practice_time_text_widget.dart';

/// The practice of this device by date, the newest first: every session with the song, its length and the takes
/// recorded during it, under the filter buttons.
///
/// Dumb: the entries (already filtered and searched), the titles, the takes of an entry ([takesBuilder]), the texts
/// and the callbacks come from above.
final class PracticeTimelineWidget extends StatelessWidget {
  static const String _separator = ' · ';
  static const String _dateSeparator = '.';
  static const String _dateTimeSeparator = ' ';
  static const String _timeSeparator = ':';
  static const String _zero = '0';

  /// The entries to show, newest first.
  final List<PracticeEntry> entries;

  /// Which items are shown.
  final PracticeEntryFilter filter;

  /// Shown when there are no entries.
  final String emptyText;

  /// The title of an entry's song ("Artist — Song").
  final String Function(PracticeEntry entry) titleOf;

  /// What tapping an entry's song does, or `null` when the song is gone.
  final VoidCallback? Function(PracticeEntry entry) onSongPressedOf;

  /// The takes of an entry (another feature's list, placed by the page).
  final Widget Function(PracticeEntry entry) takesBuilder;

  /// The texts.
  final PracticeTexts texts;

  /// Called with the filter chosen.
  final ValueChanged<PracticeEntryFilter> onFilterChanged;

  /// Called with an entry whose delete button is pressed.
  final ValueChanged<PracticeEntry> onDeletePressed;

  /// Creates a new [PracticeTimelineWidget].
  const PracticeTimelineWidget({
    super.key,
    required this.entries,
    required this.filter,
    required this.emptyText,
    required this.titleOf,
    required this.onSongPressedOf,
    required this.takesBuilder,
    required this.texts,
    required this.onFilterChanged,
    required this.onDeletePressed,
  });

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: AppTheme.maxContentWidth),
        child: ListView.builder(
          padding: const EdgeInsets.all(AppTheme.spacingMedium),
          itemCount: entries.length + 1,
          itemBuilder: (BuildContext context, int index) {
            if (index == 0) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  SegmentedButton<PracticeEntryFilter>(
                    showSelectedIcon: false,
                    segments: <ButtonSegment<PracticeEntryFilter>>[
                      ButtonSegment<PracticeEntryFilter>(
                        value: PracticeEntryFilter.all,
                        label: Text(texts.filterAllLabel),
                      ),
                      ButtonSegment<PracticeEntryFilter>(
                        value: PracticeEntryFilter.practiceOnly,
                        label: Text(texts.filterPracticeOnlyLabel),
                      ),
                      ButtonSegment<PracticeEntryFilter>(
                        value: PracticeEntryFilter.withTakes,
                        label: Text(texts.filterWithTakesLabel),
                      ),
                    ],
                    selected: <PracticeEntryFilter>{filter},
                    onSelectionChanged: (Set<PracticeEntryFilter> chosen) => onFilterChanged(chosen.first),
                  ),
                  if (entries.isEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: AppTheme.spacingLarge),
                      child: Text(
                        emptyText,
                        textAlign: TextAlign.center,
                        style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                      ),
                    ),
                ],
              );
            }
            final PracticeEntry entry = entries[index - 1];
            return Padding(
              padding: const EdgeInsets.only(top: AppTheme.spacingMedium),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  _EntryHeaderWidget(
                    title: titleOf(entry),
                    detail: _detailOf(entry),
                    onPressed: onSongPressedOf(entry),
                    onDeletePressed: entry.sessionId == null ? null : () => onDeletePressed(entry),
                    deleteTooltip: texts.deleteTooltip,
                  ),
                  if (entry.hasTakes)
                    Padding(
                      padding: const EdgeInsets.only(top: AppTheme.spacingSmall),
                      child: takesBuilder(entry),
                    ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  /// When, how long, and how many takes.
  String _detailOf(PracticeEntry entry) {
    final Duration? duration = entry.duration;
    return <String>[
      _formatDate(entry.startedAt),
      if (duration != null) texts.timeText(duration),
      if (entry.hasTakes) texts.takesText(entry.recordings.length),
    ].join(_separator);
  }

  static String _formatDate(DateTime date) {
    final DateTime local = date.toLocal();
    String two(int value) => value.toString().padLeft(AppTheme.twoDigits, _zero);
    return '${two(local.day)}$_dateSeparator${two(local.month)}$_dateSeparator${local.year}'
        '$_dateTimeSeparator${two(local.hour)}$_timeSeparator${two(local.minute)}';
  }
}

/// The song of an item with when and how long; with [onPressed], tapping it opens the song; with
/// [onDeletePressed], a button deletes the item.
final class _EntryHeaderWidget extends StatelessWidget {
  final String title;
  final String detail;
  final VoidCallback? onPressed;
  final VoidCallback? onDeletePressed;
  final String deleteTooltip;

  const _EntryHeaderWidget({
    required this.title,
    required this.detail,
    required this.onPressed,
    required this.onDeletePressed,
    required this.deleteTooltip,
  });

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(AppTheme.spacingSmall),
      child: Row(
        children: <Widget>[
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(title, style: theme.textTheme.titleMedium),
                Text(detail, style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
              ],
            ),
          ),
          if (onPressed != null) Icon(Icons.chevron_right, color: theme.colorScheme.onSurfaceVariant),
          if (onDeletePressed != null)
            IconButton(icon: const Icon(Icons.delete_outline), tooltip: deleteTooltip, onPressed: onDeletePressed),
        ],
      ),
    );
  }
}
