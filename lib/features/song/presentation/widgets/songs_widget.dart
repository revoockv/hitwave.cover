import 'package:flutter/material.dart';

import '../../../../core/presentation/theme.dart';
import '../../domain/entities/song.dart';
import '../controllers/song_view_controller.dart';
import 'artist_picker_widget.dart';
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

/// Displays songs in a vertical list, in the order given.
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

  /// Number of covers by song id.
  final Map<String, int> coverCounts;

  /// Creates a new [SongListModeWidget].
  const SongListModeWidget({
    required this.songs,
    this.coverCounts = const <String, int>{},
    required this.onSongTap,
    required this.onSongEdit,
    required this.onSongDelete,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.only(top: AppTheme.spacingSmall, bottom: _fabClearance),
      itemCount: songs.length,
      itemBuilder: (BuildContext context, int index) {
        final Song song = songs[index];
        return SongTileWidget(
          song: song,
          onTap: onSongTap,
          onEdit: onSongEdit,
          onDelete: onSongDelete,
          coverCount: coverCounts[song.id] ?? 0,
        );
      },
    );
  }
}

/// Artist mode: a compact artist list, or the songs of the selected artist.
///
/// With no artist selected it shows [ArtistPickerWidget]; with one selected
/// it shows only that artist's songs (the app bar title switches artists).
final class ArtistModeWidget extends StatelessWidget {
  /// Bottom padding so the last tile is not hidden by the floating button.
  static const double _fabClearance = 96;

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

  /// Number of covers by song id.
  final Map<String, int> coverCounts;

  /// Creates a new [ArtistModeWidget].
  const ArtistModeWidget({
    required this.songs,
    this.coverCounts = const <String, int>{},
    required this.selectedArtist,
    required this.onArtistSelected,
    required this.onSongTap,
    required this.onSongEdit,
    required this.onSongDelete,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final List<Song> artistSongs = songs.where((Song song) => song.author == selectedArtist).toList()
      ..sort(_compareByName);

    if (artistSongs.isEmpty) {
      return ArtistPickerWidget(songs: songs, onArtistSelected: onArtistSelected);
    }

    return ListView.builder(
      padding: const EdgeInsets.only(top: AppTheme.spacingSmall, bottom: _fabClearance),
      itemCount: artistSongs.length,
      itemBuilder: (BuildContext context, int index) => SongTileWidget(
        song: artistSongs[index],
        onTap: onSongTap,
        onEdit: onSongEdit,
        onDelete: onSongDelete,
        coverCount: coverCounts[artistSongs[index].id] ?? 0,
      ),
    );
  }

  static int _compareByName(Song a, Song b) => a.name.toLowerCase().compareTo(b.name.toLowerCase());
}

/// Displays songs as a list or grouped by artist, or an empty state.
final class SongsWidget extends StatelessWidget {
  /// Creates a new [SongsWidget].
  const SongsWidget({
    super.key,
    required this.songs,
    required this.viewMode,
    required this.onArtistSelected,
    required this.onSongTap,
    required this.onSongEdit,
    required this.onSongDelete,
    required this.onAddPressed,
    this.selectedArtist = '',
    this.coverCounts = const <String, int>{},
  });

  /// Number of covers by song id.
  final Map<String, int> coverCounts;

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

  @override
  Widget build(BuildContext context) {
    if (songs.isEmpty) {
      return EmptySongsWidget(onAddPressed: onAddPressed);
    }

    if (viewMode == SongViewMode.list) {
      return SongListModeWidget(
        songs: songs,
        coverCounts: coverCounts,
        onSongTap: onSongTap,
        onSongEdit: onSongEdit,
        onSongDelete: onSongDelete,
      );
    }

    return ArtistModeWidget(
      songs: songs,
      coverCounts: coverCounts,
      selectedArtist: selectedArtist,
      onArtistSelected: onArtistSelected,
      onSongTap: onSongTap,
      onSongEdit: onSongEdit,
      onSongDelete: onSongDelete,
    );
  }
}
