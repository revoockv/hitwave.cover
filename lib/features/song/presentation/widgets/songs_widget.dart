import 'package:flutter/material.dart';

import '../../../../core/presentation/theme.dart';
import '../../domain/entities/song.dart';
import '../controllers/song_view_controller.dart';
import 'song_tile_widget.dart';

/// Empty state shown when there are no songs yet.
///
/// An icon, a title, a hint and a button that calls [onAddPressed].
final class EmptySongsWidget extends StatelessWidget {
  /// Size of the music icon.
  static const double _iconSize = 72;

  /// Title of the empty state.
  static const String _title = 'Поки що немає пісень';

  /// Hint under the title.
  static const String _message = 'Додайте першу пісню або імпортуйте резервну копію.';

  /// Label of the add button.
  static const String _addLabel = 'Додати пісню';

  /// Called when the add button is pressed.
  final VoidCallback onAddPressed;

  /// Creates a new [EmptySongsWidget].
  const EmptySongsWidget({required this.onAddPressed, super.key});

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(AppTheme.spacingLarge),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Icon(Icons.library_music_outlined, size: _iconSize, color: theme.colorScheme.primary),
            const SizedBox(height: AppTheme.spacingMedium),
            Text(_title, style: theme.textTheme.titleLarge, textAlign: TextAlign.center),
            const SizedBox(height: AppTheme.spacingSmall),
            Text(
              _message,
              style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppTheme.spacingLarge),
            FilledButton.icon(onPressed: onAddPressed, icon: const Icon(Icons.add), label: const Text(_addLabel)),
          ],
        ),
      ),
    );
  }
}

/// Displays artist names as wrapping chips with song counts.
///
/// The selected artist is highlighted; tapping a chip calls [onArtistSelected].
final class ArtistListViewWidget extends StatelessWidget {
  /// Separator between the artist name and the song count.
  static const String _countSeparator = '  ';

  /// The list of all songs to extract unique artists from.
  final List<Song> songs;

  /// The currently selected artist, or empty string if no artist is selected.
  final String selectedArtist;

  /// Callback when an artist is selected.
  final void Function(String artist) onArtistSelected;

  /// Creates a new [ArtistListViewWidget].
  const ArtistListViewWidget({
    required this.songs,
    required this.selectedArtist,
    required this.onArtistSelected,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final Map<String, int> counts = <String, int>{};
    for (final Song song in songs) {
      counts[song.author] = (counts[song.author] ?? 0) + 1;
    }
    final List<String> artists = counts.keys.toList()..sort();

    return Wrap(
      spacing: AppTheme.spacingSmall,
      runSpacing: AppTheme.spacingSmall,
      children: <Widget>[
        for (final String artist in artists)
          ChoiceChip(
            label: Text('$artist$_countSeparator${counts[artist]}'),
            selected: artist == selectedArtist,
            onSelected: (bool selected) => _onChipSelected(artist, selected),
          ),
      ],
    );
  }

  void _onChipSelected(String artist, bool selected) {
    if (selected) {
      onArtistSelected(artist);
    }
  }
}

/// Displays songs in a vertical list sorted by name.
final class SongListModeWidget extends StatelessWidget {
  /// Bottom padding so the last tile is not hidden by the floating button.
  static const double _fabClearance = 96;

  /// The list of songs.
  final List<Song> songs;

  /// Called when a song tile is tapped.
  final void Function(Song song) onSongTap;

  /// Called when "edit" is chosen for a song.
  final void Function(Song song) onSongEdit;

  /// Called when "delete" is chosen for a song.
  final void Function(Song song) onSongDelete;

  /// Creates a new [SongListModeWidget].
  const SongListModeWidget({
    required this.songs,
    required this.onSongTap,
    required this.onSongEdit,
    required this.onSongDelete,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final List<Song> sortedSongs = List<Song>.from(songs)..sort(_compareByName);

    return ListView.builder(
      padding: const EdgeInsets.only(top: AppTheme.spacingSmall, bottom: _fabClearance),
      itemCount: sortedSongs.length,
      itemBuilder: (BuildContext context, int index) {
        return SongTileWidget(song: sortedSongs[index], onTap: onSongTap, onEdit: onSongEdit, onDelete: onSongDelete);
      },
    );
  }

  static int _compareByName(Song a, Song b) => a.name.toLowerCase().compareTo(b.name.toLowerCase());
}

/// Displays artist chips and, when an artist is selected, their songs.
final class ArtistModeWidget extends StatelessWidget {
  /// Bottom padding so the last tile is not hidden by the floating button.
  static const double _fabClearance = 96;

  /// Hint shown when no artist is selected.
  static const String _selectArtistHint = 'Оберіть виконавця, щоб побачити його пісні';

  /// The list of songs.
  final List<Song> songs;

  /// The currently selected artist, or empty string if no artist is selected.
  final String selectedArtist;

  /// Callback when an artist is selected.
  final void Function(String artist) onArtistSelected;

  /// Called when a song tile is tapped.
  final void Function(Song song) onSongTap;

  /// Called when "edit" is chosen for a song.
  final void Function(Song song) onSongEdit;

  /// Called when "delete" is chosen for a song.
  final void Function(Song song) onSongDelete;

  /// Creates a new [ArtistModeWidget].
  const ArtistModeWidget({
    required this.songs,
    required this.selectedArtist,
    required this.onArtistSelected,
    required this.onSongTap,
    required this.onSongEdit,
    required this.onSongDelete,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final List<Song> artistSongs = songs.where((Song song) => song.author == selectedArtist).toList()
      ..sort(SongListModeWidget._compareByName);

    return ListView(
      padding: const EdgeInsets.only(bottom: _fabClearance),
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.all(AppTheme.spacingMedium),
          child: ArtistListViewWidget(songs: songs, selectedArtist: selectedArtist, onArtistSelected: onArtistSelected),
        ),
        if (artistSongs.isEmpty)
          Padding(
            padding: const EdgeInsets.all(AppTheme.spacingLarge),
            child: Text(
              _selectArtistHint,
              style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
              textAlign: TextAlign.center,
            ),
          )
        else ...<Widget>[
          const Divider(height: 1),
          for (final Song song in artistSongs)
            SongTileWidget(song: song, onTap: onSongTap, onEdit: onSongEdit, onDelete: onSongDelete),
        ],
      ],
    );
  }
}

/// Displays songs as a list or grouped by artist, or an empty state.
final class SongsWidget extends StatelessWidget {
  /// The list of songs.
  final List<Song> songs;

  /// The view mode for displaying songs.
  final SongViewMode viewMode;

  /// The currently selected artist, or empty string if no artist is selected.
  final String selectedArtist;

  /// Callback when an artist is selected.
  final void Function(String artist) onArtistSelected;

  /// Called when a song tile is tapped.
  final void Function(Song song) onSongTap;

  /// Called when "edit" is chosen for a song.
  final void Function(Song song) onSongEdit;

  /// Called when "delete" is chosen for a song.
  final void Function(Song song) onSongDelete;

  /// Called from the empty state to add the first song.
  final VoidCallback onAddPressed;

  /// Creates a new [SongsWidget].
  const SongsWidget({
    required this.songs,
    required this.viewMode,
    required this.onArtistSelected,
    required this.onSongTap,
    required this.onSongEdit,
    required this.onSongDelete,
    required this.onAddPressed,
    this.selectedArtist = '',
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    if (songs.isEmpty) {
      return EmptySongsWidget(onAddPressed: onAddPressed);
    }

    if (viewMode == SongViewMode.list) {
      return SongListModeWidget(songs: songs, onSongTap: onSongTap, onSongEdit: onSongEdit, onSongDelete: onSongDelete);
    }

    return ArtistModeWidget(
      songs: songs,
      selectedArtist: selectedArtist,
      onArtistSelected: onArtistSelected,
      onSongTap: onSongTap,
      onSongEdit: onSongEdit,
      onSongDelete: onSongDelete,
    );
  }
}
