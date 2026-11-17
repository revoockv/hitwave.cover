import 'package:flutter/material.dart';
import 'package:watch_it/watch_it.dart';

import '../../../../core/presentation/l10n/app_translations.dart';
import '../../../../core/presentation/theme.dart';
import '../../../../core/domain/entities/result.dart';
import '../../../recordings/domain/entities/recording.dart';
import '../../../recordings/domain/entities/recordings_failure.dart';
import '../../../recordings/presentation/l10n/recordings_texts.dart';
import '../../../recordings/domain/entities/shared_song.dart';
import '../../../recordings/presentation/di/recordings_getters.dart';
import '../../../recordings/presentation/widgets/recordings_list_widget.dart';
import '../../../song/domain/entities/song.dart';
import '../../../song/presentation/di/song_getters.dart';
import '../../domain/entities/practice_entry.dart';
import '../../domain/entities/practice_entry_filter.dart';
import '../../domain/entities/practice_failure.dart';
import '../../domain/entities/practice_session.dart';
import '../di/practice_getters.dart';
import '../l10n/practice_texts.dart';
import 'delete_practice_dialog_widget.dart';
import 'practice_time_text_widget.dart';

/// The practice of this device by date, the newest first: every session with the song, its
/// length and the takes recorded during it. [filter] shows every item, only the practice without
/// takes, or only the items with takes; with a [query], only the songs whose name or artist
/// contain it.
final class PracticeTimelineWidget extends WatchingWidget {
  static const String _titleSeparator = ' — ';
  static const String _separator = ' · ';
  static const String _dateSeparator = '.';
  static const String _dateTimeSeparator = ' ';
  static const String _timeSeparator = ':';
  static const String _zero = '0';

  /// Search text; empty shows every item.
  final String query;

  /// Which items are shown.
  final PracticeEntryFilter filter;

  /// Called with the filter chosen.
  final ValueChanged<PracticeEntryFilter> onFilterChanged;

  /// Opens a song (tapping its title).
  final void Function(Song song) onSongPressed;

  /// Creates a new [PracticeTimelineWidget].
  const PracticeTimelineWidget({
    super.key,
    required this.query,
    required this.filter,
    required this.onFilterChanged,
    required this.onSongPressed,
  });

  @override
  Widget build(BuildContext context) {
    final Translations t = context.t;
    final ThemeData theme = Theme.of(context);
    final List<PracticeSession> sessions = watch(watchPracticeSessionsUseCase()).value;
    final List<Recording> recordings = watch(watchRecordingsUseCase()).value;
    final List<Song> songs = watch(watchListOfSongsUseCase()).value;
    final Map<String, Song> songsById = <String, Song>{for (final Song song in songs) song.id: song};
    String titleOf(String songId) {
      final Song? song = songsById[songId];
      return song == null ? t.common.songDeleted : '${song.author}$_titleSeparator${song.name}';
    }

    final String needle = query.trim().toLowerCase();
    final List<PracticeEntry> entries = buildPracticeTimelineUseCase(
      sessions: sessions,
      recordings: recordings,
      filter: filter,
    ).where((PracticeEntry entry) => titleOf(entry.songId).toLowerCase().contains(needle)).toList();

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
                        label: Text(t.practice.filterAll),
                      ),
                      ButtonSegment<PracticeEntryFilter>(
                        value: PracticeEntryFilter.practiceOnly,
                        label: Text(t.practice.filterPracticeOnly),
                      ),
                      ButtonSegment<PracticeEntryFilter>(
                        value: PracticeEntryFilter.withTakes,
                        label: Text(t.practice.filterWithTakes),
                      ),
                    ],
                    selected: <PracticeEntryFilter>{filter},
                    onSelectionChanged: (Set<PracticeEntryFilter> chosen) => onFilterChanged(chosen.first),
                  ),
                  if (entries.isEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: AppTheme.spacingLarge),
                      child: Text(
                        _emptyText(t, needle),
                        textAlign: TextAlign.center,
                        style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                      ),
                    ),
                ],
              );
            }
            final PracticeEntry entry = entries[index - 1];
            final Song? song = songsById[entry.songId];
            return Padding(
              padding: const EdgeInsets.only(top: AppTheme.spacingMedium),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  _EntryHeaderWidget(
                    title: titleOf(entry.songId),
                    detail: _detailOf(t, entry),
                    onPressed: song == null ? null : () => onSongPressed(song),
                    onDeletePressed: entry.sessionId == null ? null : () => _onDeletePressed(context, entry),
                  ),
                  if (entry.hasTakes)
                    Padding(
                      padding: const EdgeInsets.only(top: AppTheme.spacingSmall),
                      child: RecordingsListWidget(
                        recordings: entry.recordings,
                        emptyText: t.recordings.noTakes,
                        songOf: (Recording recording) =>
                            song == null ? null : SharedSong(author: song.author, name: song.name),
                        shrinkWrap: true,
                      ),
                    ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  /// Asks, then deletes the session of [entry] and — when chosen — its takes.
  Future<void> _onDeletePressed(BuildContext context, PracticeEntry entry) async {
    final String? sessionId = entry.sessionId;
    if (sessionId == null) return;
    final bool? withTakes = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) => DeletePracticeDialogWidget(takeCount: entry.recordings.length),
    );
    if (withTakes == null || !context.mounted) return;
    final Translations t = context.t;
    final ScaffoldMessengerState messenger = ScaffoldMessenger.of(context);
    if (withTakes) {
      if (entry.recordings.any((Recording r) => r.id == watchPlaybackUseCase().value.recordingId)) {
        await stopPlaybackUseCase();
      }
      for (final Recording recording in entry.recordings) {
        final Result<void, RecordingsFailure> deleted = await deleteRecordingUseCase(recording.id);
        if (deleted case FailureResult<void, RecordingsFailure>(:final RecordingsFailure failure)) {
          messenger.showSnackBar(SnackBar(content: Text(failure.text(t))));
          return;
        }
      }
    }
    final Result<void, PracticeFailure> result = await deletePracticeSessionUseCase(sessionId);
    if (result case FailureResult<void, PracticeFailure>(:final PracticeFailure failure)) {
      messenger.showSnackBar(SnackBar(content: Text(failure.text(t))));
    }
  }

  String _emptyText(Translations t, String needle) {
    if (needle.isNotEmpty) return t.common.nothingFound;
    return switch (filter) {
      PracticeEntryFilter.withTakes => t.recordings.noCovers,
      PracticeEntryFilter.all || PracticeEntryFilter.practiceOnly => t.practice.noPracticeYet,
    };
  }

  /// When, how long, and how many takes.
  static String _detailOf(Translations t, PracticeEntry entry) {
    final Duration? duration = entry.duration;
    return <String>[
      _formatDate(entry.startedAt),
      if (duration != null) PracticeTimeTextWidget.format(t, duration),
      if (entry.hasTakes) t.practice.takesCount(n: entry.recordings.length),
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

  const _EntryHeaderWidget({
    required this.title,
    required this.detail,
    required this.onPressed,
    required this.onDeletePressed,
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
            IconButton(
              icon: const Icon(Icons.delete_outline),
              tooltip: context.t.common.delete,
              onPressed: onDeletePressed,
            ),
        ],
      ),
    );
  }
}
