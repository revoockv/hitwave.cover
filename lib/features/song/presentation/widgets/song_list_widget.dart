import 'package:flutter/material.dart';
import 'package:hitwave.cover/features/song/domain/entities/song.dart';
import 'package:hitwave.cover/features/song/presentation/pages/home_page.dart';

import 'song_tile_widget.dart';

/// Displays artist names as horizontal scrollable chips.
///
/// Each artist is rendered as a [Chip] that can be selected to filter songs.
final class ArtistListViewWidget extends StatelessWidget {
  /// Empty artist list message.
  static const String _emptyArtistListMessage = 'Артисти не знайдені';

  /// Semi-transparent alpha value for selected chip background.
  static const double _selectedChipAlpha = 0.2;

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
    final List<String> uniqueArtists = _getUniqueArtists();

    if (uniqueArtists.isEmpty) {
      return const Center(
        child: Text(_emptyArtistListMessage),
      );
    }

    uniqueArtists.sort();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: uniqueArtists.map((String artist) {
            final bool isSelected = artist == selectedArtist;

            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: FilterChip(
                label: Text(artist),
                selected: isSelected,
                onSelected: (bool value) {
                  if (value) {
                    onArtistSelected(artist);
                  }
                },
                selectedColor: Theme.of(context).primaryColor.withValues(alpha: _selectedChipAlpha),
                checkmarkColor: Theme.of(context).primaryColor,
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  List<String> _getUniqueArtists() {
    final Set<String> artistSet = songs.map((Song song) => song.author).toSet();
    return artistSet.toList();
  }
}

/// Displays songs in a vertical list sorted by name.
///
/// Each song is rendered as a [SongTileWidget] widget.
final class SongListModeWidget extends StatelessWidget {
  /// Empty song list message.
  static const String _emptySongListMessage = 'Список пісень порожній';

  /// The list of songs.
  final List<Song> songs;

  /// Callback when a song tile is tapped.
  final void Function(Song song) onSongTap;

  /// Creates a new [SongListModeWidget].
  const SongListModeWidget({
    required this.songs,
    required this.onSongTap,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    if (songs.isEmpty) {
      return const Center(
        child: Text(_emptySongListMessage),
      );
    }

    final List<Song> sortedSongs = _getSortedSongs();

    return ListView.builder(
      itemCount: sortedSongs.length,
      itemBuilder: (BuildContext context, int index) {
        return SongTileWidget(song: sortedSongs[index], onTap: onSongTap);
      },
    );
  }

  List<Song> _getSortedSongs() {
    final List<Song> sorted = List<Song>.from(songs);
    sorted.sort((Song a, Song b) => a.name.compareTo(b.name));
    return sorted;
  }
}

/// Displays songs for a selected artist in a horizontal list.
///
/// Shows an empty message when no songs exist for the artist, or a
/// horizontally scrollable list of [SongTileWidget] widgets otherwise.
final class ArtistSongsListWidget extends StatelessWidget {
  /// Empty songs for artist message.
  static const String _emptyArtistSongsMessage = 'У цього артиста немає пісень';

  /// Height of the horizontal song list.
  static const double _horizontalListHeight = 120;

  /// Width of each song tile in horizontal list.
  static const double _horizontalSongTileWidth = 280;

  /// The list of songs for the selected artist.
  final List<Song> songs;

  /// Callback when a song tile is tapped.
  final void Function(Song song) onSongTap;

  /// Creates a new [ArtistSongsListWidget].
  const ArtistSongsListWidget({
    required this.songs,
    required this.onSongTap,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    if (songs.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(16),
        child: Center(child: Text(_emptyArtistSongsMessage)),
      );
    }

    return SizedBox(
      height: ArtistSongsListWidget._horizontalListHeight,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: songs.length,
        itemBuilder: (BuildContext context, int index) {
          final Song song = songs[index];
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: SizedBox(
              width: ArtistSongsListWidget._horizontalSongTileWidth,
              child: SongTileWidget(song: song, onTap: onSongTap),
            ),
          );
        },
      ),
    );
  }
}

/// Displays songs grouped by artist in horizontal lists.
///
/// Shows a horizontal list of artist chips at the top, and when an artist
/// is selected, displays their songs in a horizontal list below.
final class ArtistModeWidget extends StatelessWidget {
  /// Empty song list message.
  static const String _emptySongListMessage = 'Список пісень порожній';

  /// The list of songs.
  final List<Song> songs;

  /// The currently selected artist, or empty string if no artist is selected.
  final String selectedArtist;

  /// Callback when an artist is selected.
  final void Function(String artist) onArtistSelected;

  /// Callback when a song tile is tapped.
  final void Function(Song song) onSongTap;

  /// Creates a new [ArtistModeWidget].
  const ArtistModeWidget({
    required this.songs,
    required this.selectedArtist,
    required this.onArtistSelected,
    required this.onSongTap,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final List<String> uniqueArtists = _getUniqueArtists();

    if (uniqueArtists.isEmpty) {
      return const Center(
        child: Text(_emptySongListMessage),
      );
    }

    return Column(
      children: <Widget>[
        ArtistListViewWidget(
          songs: songs,
          selectedArtist: selectedArtist,
          onArtistSelected: onArtistSelected,
        ),
        if (selectedArtist.isNotEmpty) ..._buildArtistSongs(),
      ],
    );
  }

  List<Widget> _buildArtistSongs() {
    final List<Song> artistSongs = _getSongsByArtist(selectedArtist);

    return [
      ArtistSongsListWidget(
        songs: artistSongs,
        onSongTap: onSongTap,
      ),
    ];
  }

  List<String> _getUniqueArtists() {
    final Set<String> artistSet = songs.map((Song song) => song.author).toSet();
    return artistSet.toList();
  }

  List<Song> _getSongsByArtist(String artist) {
    return songs.where((Song song) => song.author == artist).toList();
  }
}

/// Displays songs as a [ListView] or horizontal artist/song lists.
///
/// Each song is rendered as a [SongTileWidget] widget.
final class SongListViewWidget extends StatelessWidget {

  /// The list of songs.
  final List<Song> songs;

  /// The view mode for displaying songs.
  final SongViewMode viewMode;

  /// The currently selected artist, or empty string if no artist is selected.
  final String selectedArtist;

  /// Callback when an artist is selected.
  final void Function(String artist) onArtistSelected;

  /// Callback when a song tile is tapped.
  final void Function(Song song) onSongTap;

  /// Creates a new [SongListViewWidget].
  const SongListViewWidget({
    required this.songs,
    required this.viewMode,
    required this.onArtistSelected,
    required this.onSongTap,
    this.selectedArtist = '',
    super.key,
  });

  /// Builds the song list view.
  ///
  /// Returns an empty state message when the list is empty, or a [ListView.builder]
  /// displaying all songs as [SongTileWidget] widgets.
  @override
  Widget build(BuildContext context) {
    if (viewMode == SongViewMode.list) {
      return SongListModeWidget(
        songs: songs,
        onSongTap: onSongTap,
      );
    }

    return ArtistModeWidget(
      songs: songs,
      selectedArtist: selectedArtist,
      onArtistSelected: onArtistSelected,
      onSongTap: onSongTap,
    );
  }
}
