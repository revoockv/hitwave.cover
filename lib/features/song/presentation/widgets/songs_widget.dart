import 'package:flutter/material.dart';

import '../../../../core/presentation/theme.dart';
import '../../domain/entities/song.dart';
import '../../domain/entities/song_sort.dart';
import 'artist_picker_widget.dart';
import 'song_tile_widget.dart';
import 'songs_tab_widget.dart';

/// The texts of [EmptySongsWidget].
final class EmptySongsTexts {
  /// Title of the empty state.
  final String titleText;

  /// Hint under the title.
  final String messageText;

  /// Label of the add button.
  final String addLabel;

  /// Creates the texts.
  const EmptySongsTexts({required this.titleText, required this.messageText, required this.addLabel});
}

/// Empty state shown when there are no songs yet.
///
/// An icon, a title, a hint and a button that calls [onAddPressed].
final class EmptySongsWidget extends StatelessWidget {
  /// Size of the music icon.
  static const double _iconSize = 72;

  /// The texts.
  final EmptySongsTexts texts;

  /// Called when the add button is pressed.
  final VoidCallback onAddPressed;

  /// Creates a new [EmptySongsWidget].
  const EmptySongsWidget({required this.texts, required this.onAddPressed, super.key});

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
            Text(texts.titleText, style: theme.textTheme.titleLarge, textAlign: TextAlign.center),
            const SizedBox(height: AppTheme.spacingSmall),
            Text(
              texts.messageText,
              style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppTheme.spacingLarge),
            FilledButton.icon(onPressed: onAddPressed, icon: const Icon(Icons.add), label: Text(texts.addLabel)),
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

  /// How many covers the song with an id has.
  final int Function(String songId) coverCountOf;

  /// The texts of the list.
  final SongListTexts texts;

  /// Creates a new [SongListModeWidget].
  const SongListModeWidget({
    required this.songs,
    required this.coverCountOf,
    required this.texts,
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
          coverCount: coverCountOf(song.id),
          texts: texts.tile,
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

  /// How many covers the song with an id has.
  final int Function(String songId) coverCountOf;

  /// The texts of the list.
  final SongListTexts texts;

  /// Creates a new [ArtistModeWidget].
  const ArtistModeWidget({
    required this.songs,
    required this.coverCountOf,
    required this.texts,
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
      return ArtistPickerWidget(songs: songs, texts: texts.picker, onArtistSelected: onArtistSelected);
    }

    return ListView.builder(
      padding: const EdgeInsets.only(top: AppTheme.spacingSmall, bottom: _fabClearance),
      itemCount: artistSongs.length,
      itemBuilder: (BuildContext context, int index) => SongTileWidget(
        song: artistSongs[index],
        onTap: onSongTap,
        onEdit: onSongEdit,
        onDelete: onSongDelete,
        coverCount: coverCountOf(artistSongs[index].id),
        texts: texts.tile,
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
    required this.coverCountOf,
    required this.texts,
  });

  /// How many covers the song with an id has.
  final int Function(String songId) coverCountOf;

  /// The texts of the list.
  final SongListTexts texts;

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
      return EmptySongsWidget(texts: texts.empty, onAddPressed: onAddPressed);
    }

    if (viewMode == SongViewMode.list) {
      return SongListModeWidget(
        songs: songs,
        coverCountOf: coverCountOf,
        texts: texts,
        onSongTap: onSongTap,
        onSongEdit: onSongEdit,
        onSongDelete: onSongDelete,
      );
    }

    return ArtistModeWidget(
      songs: songs,
      coverCountOf: coverCountOf,
      texts: texts,
      selectedArtist: selectedArtist,
      onArtistSelected: onArtistSelected,
      onSongTap: onSongTap,
      onSongEdit: onSongEdit,
      onSongDelete: onSongDelete,
    );
  }
}
