import 'package:flutter/material.dart';

import '../../domain/entities/song.dart';

/// Actions offered in the menu of a song tile.
enum _SongTileAction { edit, delete }

/// Displays a single song: an initial avatar, its name, author and album.
///
/// Knows nothing about use cases: tapping the tile calls [onTap], the menu
/// calls [onEdit] or [onDelete].
final class SongTileWidget extends StatelessWidget {
  /// Separator between the author and the album.
  static const String _separator = ' · ';

  /// Shown in the avatar when the song has no name.
  static const String _fallbackInitial = '♪';

  /// Tooltip of the actions menu.
  static const String _menuTooltip = 'Дії';

  /// Label of the edit action.
  static const String _editLabel = 'Редагувати';

  /// Label of the delete action.
  static const String _deleteLabel = 'Видалити';

  /// The [Song] to display.
  final Song song;

  /// Called when the tile is tapped.
  final void Function(Song song) onTap;

  /// Called when "edit" is chosen in the menu.
  final void Function(Song song) onEdit;

  /// Called when "delete" is chosen in the menu.
  final void Function(Song song) onDelete;

  /// Creates a new [SongTileWidget].
  const SongTileWidget({
    required this.song,
    required this.onTap,
    required this.onEdit,
    required this.onDelete,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final ColorScheme colorScheme = Theme.of(context).colorScheme;
    final String? album = song.album;
    final String subtitle = album == null || album.isEmpty ? song.author : '${song.author}$_separator$album';
    final String trimmedName = song.name.trim();
    final String initial = trimmedName.isEmpty ? _fallbackInitial : trimmedName.characters.first.toUpperCase();

    return ListTile(
      leading: CircleAvatar(
        backgroundColor: colorScheme.primaryContainer,
        foregroundColor: colorScheme.onPrimaryContainer,
        child: Text(initial),
      ),
      title: Text(song.name, maxLines: 1, overflow: TextOverflow.ellipsis),
      subtitle: Text(subtitle, maxLines: 1, overflow: TextOverflow.ellipsis),
      trailing: PopupMenuButton<_SongTileAction>(
        tooltip: _menuTooltip,
        onSelected: _onActionSelected,
        itemBuilder: _buildMenuItems,
      ),
      onTap: _onTilePressed,
    );
  }

  List<PopupMenuEntry<_SongTileAction>> _buildMenuItems(BuildContext context) {
    final Color errorColor = Theme.of(context).colorScheme.error;
    return <PopupMenuEntry<_SongTileAction>>[
      const PopupMenuItem<_SongTileAction>(
        value: _SongTileAction.edit,
        child: ListTile(leading: Icon(Icons.edit_outlined), title: Text(_editLabel)),
      ),
      PopupMenuItem<_SongTileAction>(
        value: _SongTileAction.delete,
        child: ListTile(
          leading: Icon(Icons.delete_outline, color: errorColor),
          title: Text(_deleteLabel, style: TextStyle(color: errorColor)),
        ),
      ),
    ];
  }

  void _onTilePressed() {
    onTap(song);
  }

  void _onActionSelected(_SongTileAction action) {
    switch (action) {
      case _SongTileAction.edit:
        onEdit(song);
      case _SongTileAction.delete:
        onDelete(song);
    }
  }
}
