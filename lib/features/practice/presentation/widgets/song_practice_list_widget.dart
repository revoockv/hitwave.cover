import 'package:flutter/material.dart';

import '../../../../core/presentation/l10n/app_translations.dart';
import '../../domain/entities/song_practice.dart';
import 'practice_time_text_widget.dart';

/// Songs with their practice time and takes.
final class SongPracticeListWidget extends StatelessWidget {
  static const String _separator = ' · ';

  /// The songs, in the order to show.
  final List<SongPractice> songs;

  /// Title of a song by its id.
  final String Function(String songId) titleOf;

  /// Shown when [songs] is empty.
  final String emptyText;

  /// Creates a new [SongPracticeListWidget].
  const SongPracticeListWidget({super.key, required this.songs, required this.titleOf, required this.emptyText});

  @override
  Widget build(BuildContext context) {
    final Translations t = context.t;
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
            title: Text(titleOf(song.songId), maxLines: 1, overflow: TextOverflow.ellipsis),
            trailing: Text(
              song.takes > 0
                  ? '${PracticeTimeTextWidget.format(t, song.time)}$_separator${t.practice.takesCount(n: song.takes)}'
                  : PracticeTimeTextWidget.format(t, song.time),
              style: theme.textTheme.bodyMedium,
            ),
          ),
      ],
    );
  }
}
