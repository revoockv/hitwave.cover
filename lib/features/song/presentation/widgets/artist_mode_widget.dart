import 'package:flutter/material.dart';
import '../../../../core/presentation/theme.dart';
import '../../domain/entities/song.dart';
import 'artist_picker_widget.dart';
import 'song_tile_widget.dart';
import 'songs_tab_widget.dart';

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
