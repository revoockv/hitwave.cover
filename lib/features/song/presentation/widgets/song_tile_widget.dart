import 'package:flutter/material.dart';
import 'package:hitwave.cover/features/song/domain/entities/song.dart';

import 'delete_song_dialog_widget.dart';
import 'edit_song_dialog_widget.dart';

/// Displays a single song with its name, author, and optional album.
///
/// Shows an edit and delete button for CRUD operations.
/// Tapping the tile navigates to the lyrics page.
final class SongTileWidget extends StatelessWidget {
  /// Icon size for the trailing buttons.
  static const double iconSize = 20.0;

  /// The [Song] to display.
  final Song song;

  /// Callback when the tile is tapped.
  final void Function(Song song) onTap;

  /// Creates a new [SongTileWidget].
  const SongTileWidget({required this.song, required this.onTap, super.key});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text(song.name),
      subtitle: Text(song.author),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
           IconButton(
            icon: const Icon(Icons.edit, size: SongTileWidget.iconSize),
            onPressed: () => _showEditDialog(context),
          ),
          IconButton(
            icon: const Icon(Icons.delete, size: SongTileWidget.iconSize),
            onPressed: () => _showDeleteConfirmation(context),
          ),
        ],
      ),
      onTap: () => _handleTap(song),
    );
  }

  void _handleTap(Song song) {
    onTap(song);
  }

  void _showEditDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) => EditSongDialogWidget(song: song),
    );
  }

  void _showDeleteConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) => DeleteSongDialogWidget(song: song),
    );
  }
}
