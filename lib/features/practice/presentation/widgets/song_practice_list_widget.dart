import 'package:flutter/material.dart';

import '../../domain/entities/song_practice.dart';
import 'practice_time_text_widget.dart';

/// Songs with their practice time and takes; tapping one opens it.
final class SongPracticeListWidget extends StatelessWidget {
  static const String _separator = ' · ';

  /// The songs, in the order to show.
  final List<SongPractice> songs;

  /// Title of a song by its id.
  final String Function(String songId) titleOf;

  /// What tapping a song does (opens it) by its id, or `null` when it does nothing.
  final VoidCallback? Function(String songId) onPressedOf;

  /// Shown when [songs] is empty.
  final String emptyText;

  /// How times and takes are written.
  final PracticeTexts texts;

  /// Creates a new [SongPracticeListWidget].
  const SongPracticeListWidget({
    super.key,
    required this.songs,
    required this.titleOf,
    required this.onPressedOf,
    required this.emptyText,
    required this.texts,
  });

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    if (songs.isEmpty) {
      return Text(emptyText, style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant));
    }
    return Column(
      children: <Widget>[
        for (final SongPractice song in songs)
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.music_note_outlined),
            // The time goes under the name, so a long name keeps the whole line.
            title: Text(titleOf(song.songId), maxLines: 2, overflow: TextOverflow.ellipsis),
            subtitle: Text(
              song.takes > 0
                  ? '${texts.timeText(song.time)}$_separator${texts.takesText(song.takes)}'
                  : texts.timeText(song.time),
              style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
            ),
            onTap: onPressedOf(song.songId),
          ),
      ],
    );
  }
}
