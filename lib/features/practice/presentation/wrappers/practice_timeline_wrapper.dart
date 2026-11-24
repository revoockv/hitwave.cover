import 'package:flutter/material.dart';
import 'package:watch_it/watch_it.dart';

import '../../../recordings/domain/entities/recording.dart';
import '../../../recordings/presentation/di/recordings_getters.dart';
import '../../../song/domain/entities/song.dart';
import '../../../song/presentation/di/song_getters.dart';
import '../../domain/entities/practice_entry.dart';
import '../../domain/entities/practice_entry_filter.dart';
import '../../domain/entities/practice_session.dart';
import '../di/practice_getters.dart';
import '../widgets/practice_time_text_widget.dart';
import '../widgets/practice_timeline_widget.dart';

/// Builds the practice entries from the sessions, the takes and the songs — filtered by [filter] and searched by
/// [query] — and gives them to [PracticeTimelineWidget].
final class PracticeTimelineWrapper extends WatchingWidget {
  static const String _titleSeparator = ' — ';

  /// Search text; empty shows every item.
  final String query;

  /// Which items are shown.
  final PracticeEntryFilter filter;

  /// The takes of an entry, placed by the page.
  final Widget Function(PracticeEntry entry, Song? song) takesBuilder;

  /// The texts.
  final PracticeTexts texts;

  /// Called with the filter chosen.
  final ValueChanged<PracticeEntryFilter> onFilterChanged;

  /// Opens a song (tapping its title).
  final ValueChanged<Song> onSongPressed;

  /// Called with an entry to delete; the page asks and deletes it.
  final ValueChanged<PracticeEntry> onDeletePressed;

  /// Creates the wrapper.
  const PracticeTimelineWrapper({
    required this.query,
    required this.filter,
    required this.takesBuilder,
    required this.texts,
    required this.onFilterChanged,
    required this.onSongPressed,
    required this.onDeletePressed,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final List<PracticeSession> sessions = watch(watchPracticeSessionsUseCase()).value;
    final List<Recording> recordings = watch(watchRecordingsUseCase()).value;
    final List<Song> songs = watch(watchListOfSongsUseCase()).value;
    Song? songOf(PracticeEntry entry) => songs.where((Song song) => song.id == entry.songId).firstOrNull;
    String titleOf(PracticeEntry entry) {
      final Song? song = songOf(entry);
      return song == null ? texts.songDeletedText : '${song.author}$_titleSeparator${song.name}';
    }

    final String needle = query.trim().toLowerCase();
    final List<PracticeEntry> entries = buildPracticeTimelineUseCase(
      sessions: sessions,
      recordings: recordings,
      filter: filter,
    ).where((PracticeEntry entry) => titleOf(entry).toLowerCase().contains(needle)).toList();

    return PracticeTimelineWidget(
      entries: entries,
      filter: filter,
      emptyText: _emptyText(needle),
      titleOf: titleOf,
      onSongPressedOf: (PracticeEntry entry) => _pressedOf(songOf(entry)),
      takesBuilder: (PracticeEntry entry) => takesBuilder(entry, songOf(entry)),
      texts: texts,
      onFilterChanged: onFilterChanged,
      onDeletePressed: onDeletePressed,
    );
  }

  VoidCallback? _pressedOf(Song? song) => song == null ? null : () => onSongPressed(song);

  String _emptyText(String needle) {
    if (needle.isNotEmpty) return texts.nothingFoundText;
    return switch (filter) {
      PracticeEntryFilter.withTakes => texts.noCoversText,
      PracticeEntryFilter.all || PracticeEntryFilter.practiceOnly => texts.noPracticeYetText,
    };
  }
}
