import 'package:flutter/material.dart';
import 'package:watch_it/watch_it.dart';

import '../../domain/entities/song.dart';
import '../../domain/use_cases/watch_list_of_songs_use_case.dart';
import '../widgets/add_song_view.dart';
import '../widgets/song_list_view.dart';
import 'lyrics_page.dart';

/// Main song management page.
///
/// Displays a list of songs with an option to add new songs.
/// Uses [WatchingWidget] to reactively watch song list changes.
final class SongPage extends WatchingWidget {
  /// Creates a new [SongPage].
  const SongPage({super.key});

  @override
  Widget build(BuildContext context) {
    final List<Song> songs = watchValue((WatchListOfSongsUseCase watchListOfSongs) => watchListOfSongs());

    return Scaffold(
      appBar: AppBar(
        title: const Text('Мої пісні'),
        actions: <Widget>[
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _showAddSongDialog(context),
          ),
        ],
      ),
      body: SongListView(
        songs: songs,
        onSongTap: (Song song) => _navigateToLyrics(context, song),
      ),
    );
  }

  void _navigateToLyrics(BuildContext context, Song song) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (BuildContext context) => LyricsPage(song: song),
      ),
    );
  }

  void _showAddSongDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) => AddSongView(),
    );
  }
}
