import 'package:flutter/material.dart';
import '../../../../core/presentation/theme.dart';
import '../../domain/entities/song.dart';
import 'song_tile_widget.dart';
import 'songs_tab_widget.dart';

/// Displays songs in a vertical list, in the order given.
final class SongListModeWidget extends StatelessWidget {
  /// Bottom padding so the last tile is not hidden by the floating button.
  static const double _fabClearance = 96;

  /// The list of songs.
  final List<Song> songs;

  /// Called when a song tile is tapped.
  final void Function(Song song) onSongTap;

  /// Called when "edit" is chosen for a song.
  final void Function(Song song) onSongEdit;

  /// Called when "delete" is chosen for a song.
  final void Function(Song song) onSongDelete;

  /// How many covers the song with an id has.
  final int Function(String songId) coverCountOf;

  /// The texts of the list.
  final SongListTexts texts;

  /// Creates a new [SongListModeWidget].
  const SongListModeWidget({
    required this.songs,
    required this.coverCountOf,
    required this.texts,
    required this.onSongTap,
    required this.onSongEdit,
    required this.onSongDelete,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: AppTheme.clearOfSystemBar(
        context,
        const EdgeInsets.only(top: AppTheme.spacingSmall, bottom: _fabClearance),
      ),
      itemCount: songs.length,
      itemBuilder: (BuildContext context, int index) {
        final Song song = songs[index];
        return SongTileWidget(
          song: song,
          onTap: onSongTap,
          onEdit: onSongEdit,
          onDelete: onSongDelete,
          coverCount: coverCountOf(song.id),
          texts: texts.tile,
        );
      },
    );
  }
}
