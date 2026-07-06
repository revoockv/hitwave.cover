import 'package:flutter/material.dart';
import 'package:hitwave.cover/features/song/domain/entities/song.dart';

import 'song_tile.dart';

/// Displays a list of songs as a [ListView].
///
/// Each song is rendered as a [SongTile] widget.
final class SongListView extends StatelessWidget {
  /// The list of songs.
  final List<Song> songs;

  /// Callback when a song tile is tapped.
  final void Function(Song song) onSongTap;

  /// Creates a new [SongListView].
  const SongListView({required this.songs, required this.onSongTap, super.key});

  @override
  Widget build(BuildContext context) {
    if (songs.isEmpty) {
      return const Center(
        child: Text('Список пісень порожній'),
      );
    }

    return ListView.builder(
      itemCount: songs.length,
      itemBuilder: (BuildContext context, int index) {
        return SongTile(song: songs[index], onTap: onSongTap);
      },
    );
  }
}
