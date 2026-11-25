import 'package:flutter/material.dart';
import '../../domain/entities/song.dart';
import '../../domain/entities/song_sort.dart';
import 'songs_tab_widget.dart';
import 'empty_songs_widget.dart';
import 'song_list_mode_widget.dart';
import 'artist_mode_widget.dart';

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
