import 'package:flutter/material.dart';
import 'package:hitwave.cover/features/song/domain/entities/song.dart';

import 'song_tile_widget.dart';

/// Displays a list of songs as a [ListView].
///
/// Each song is rendered as a [SongTileWidget] widget.
final class SongListViewWidget extends StatelessWidget {
  /// Empty song list message.
  static const String _emptySongListMessage = 'Список пісень порожній';

  /// The list of songs.
  final List<Song> songs;

  /// Callback when a song tile is tapped.
  final void Function(Song song) onSongTap;

  /// Creates a new [SongListViewWidget].
  const SongListViewWidget({required this.songs, required this.onSongTap, super.key});

  /// Builds the song list view.
  ///
  /// Returns an empty state message when the list is empty, or a [ListView.builder]
  /// displaying all songs as [SongTileWidget] widgets.
  @override
  Widget build(BuildContext context) {
    if (songs.isEmpty) {
      return const Center(
        child: Text(_emptySongListMessage),
      );
    }

    return ListView.builder(
      itemCount: songs.length,
      itemBuilder: (BuildContext context, int index) {
        return SongTileWidget(song: songs[index], onTap: onSongTap);
      },
    );
  }
}
