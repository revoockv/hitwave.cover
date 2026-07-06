import 'package:flutter/material.dart';
import 'package:watch_it/watch_it.dart';

import '../di/song_getters.dart';
import '../domain/repositories/song_repository.dart';
import 'widgets/song_list_view.dart';
import 'widgets/add_song_view.dart';

/// Main song management page.
///
/// Displays a list of songs with an option to add new songs.
/// Uses [WatchingWidget] to reactively watch song list changes.
final class SongPage extends WatchingWidget {
  /// Creates a new [SongPage].
  const SongPage({super.key});

  @override
  Widget build(BuildContext context) {
    final ValueNotifier<List<Song>> songs = watchValue((SongRepository r) => r.songs);

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
      body: SongListView(songs: songs),
    );
  }

  void _showAddSongDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) => AddSongView(),
    );
  }
}
