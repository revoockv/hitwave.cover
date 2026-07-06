import 'package:flutter/material.dart';
import 'package:hitwave.cover/features/song/domain/entities/song.dart';

import 'song_tile.dart';

/// Displays a list of songs as a [ListView].
///
/// Each song is rendered as a [SongTile] widget.
final class SongListView extends StatelessWidget {
  /// The [ValueNotifier] containing the list of songs.
  final List<Song> songs;

  /// Creates a new [SongListView].
  const SongListView({required this.songs, super.key});

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
        return SongTile(song: songs[index]);
      },
    );
  }
}
