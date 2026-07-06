import 'package:flutter/material.dart';
import 'package:hitwave.cover/features/song/domain/entities/song.dart';

import 'delete_song_dialog.dart';
import 'edit_song_dialog.dart';

/// Displays a single song with its name, author, and optional album.
///
/// Shows an edit and delete button for CRUD operations.
/// Tapping the tile navigates to the lyrics page.
final class SongTile extends StatelessWidget {
  /// The [Song] to display.
  final Song song;

  /// Callback when the tile is tapped.
  final void Function(Song song) onTap;

  /// Creates a new [SongTile].
  const SongTile({required this.song, required this.onTap, super.key});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text(song.name),
      subtitle: Text(song.author),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () => _showEditDialog(context),
          ),
          IconButton(
            icon: const Icon(Icons.delete),
            onPressed: () => _showDeleteConfirmation(context),
          ),
        ],
      ),
      onTap: () => onTap(song),
    );
  }

  void _showEditDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) => EditSongDialog(song: song),
    );
  }

  void _showDeleteConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) => DeleteSongDialog(song: song),
    );
  }
}
