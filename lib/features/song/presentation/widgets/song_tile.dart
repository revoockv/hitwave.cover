import 'package:flutter/material.dart';
import 'package:hitwave.cover/features/song/domain/entities/song.dart';

/// Displays a single song with its name, author, and optional album.
///
/// Shows an edit and delete button for CRUD operations.
final class SongTile extends StatelessWidget {
  /// The [Song] to display.
  final Song song;

  /// Creates a new [SongTile].
  const SongTile({required this.song, super.key});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text(song.name),
      subtitle: Text(song.album ?? song.author),
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
    );
  }

  void _showEditDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) => _EditSongDialog(song: song),
    );
  }

  void _showDeleteConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) => _DeleteSongDialog(song: song),
    );
  }
}
