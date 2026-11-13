import 'package:flutter/material.dart';
import 'package:hitwave.cover/features/song/domain/entities/song.dart';
import 'package:hitwave.cover/features/song/presentation/pages/delete_song_page.dart';
import 'package:hitwave.cover/features/song/presentation/pages/edit_song_page.dart';

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
            onPressed: () => _showEditPage(context),
          ),
          IconButton(
            icon: const Icon(Icons.delete, size: SongTileWidget.iconSize),
            onPressed: () => _showDeletePage(context),
          ),
        ],
      ),
      onTap: () => _handleTap(song),
    );
  }

  void _handleTap(Song song) {
    onTap(song);
  }

  void _showEditPage(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (BuildContext context) => EditSongPage(song: song),
      ),
    );
  }

  void _showDeletePage(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (BuildContext context) => DeleteSongPage(song: song),
      ),
    );
  }
}
