import 'package:flutter/material.dart';
import 'package:hitwave.cover/features/song/domain/entities/song.dart';
import 'package:hitwave.cover/features/song/presentation/pages/home_page.dart';

import 'song_tile_widget.dart';

/// Displays artist names as wrapable chips with song counts.
///
/// Each artist is rendered as a [FilterChip] showing the artist name and the
/// number of songs they have. Chips wrap to multiple lines when needed.
/// Uses a blocky, vibrant style with clear selected/unselected states.
final class ArtistListViewWidget extends StatelessWidget {
  /// Empty artist list message.
  static const String _emptyArtistListMessage = 'Артисти не знайдені';

  /// Semi-transparent alpha value for selected chip background.
  static const double _selectedChipAlpha = 0.2;

  /// Border radius for artist chips (blocky rounded corners).
  static const double _chipBorderRadius = 12;

  /// Padding inside artist chips.
  static const EdgeInsets _chipPadding = EdgeInsets.symmetric(
    horizontal: 12,
    vertical: 8,
  );

  /// Unselected chip border width.
  static const double _unselectedBorderWidth = 1;

  /// Selected chip border width.
  static const double _selectedBorderWidth = 1.5;

  /// Spacing between artist chips.
  static const double _chipSpacing = 8;

  /// Run spacing between wrapped chip rows.
  static const double _chipRunSpacing = 8;

  /// Alpha value for song count text.
  static const double _songCountAlpha = 0.7;

  /// Alpha value for unselected chip border.
  static const double _unselectedBorderAlpha = 0.3;

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
      return const Center(child: Text(_emptyArtistListMessage));
    }

    uniqueArtists.sort();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Wrap(
        spacing: ArtistListViewWidget._chipSpacing,
        runSpacing: ArtistListViewWidget._chipRunSpacing,
        children: uniqueArtists.map((String artist) {
          final bool isSelected = artist == selectedArtist;
          final int songCount = _getSongCountForArtist(artist);
          final ColorScheme colorScheme = Theme.of(context).colorScheme;

          return FilterChip(
            label: Row(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Text(
                  artist,
                  style: TextStyle(
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(left: 6),
                  child: Text(
                    '($songCount)',
                    style: TextStyle(
                      color: colorScheme.onSurface.withValues(
                        alpha: ArtistListViewWidget._songCountAlpha,
                      ),
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ),
              ],
            ),
            selected: isSelected,
            onSelected: (bool value) {
              if (value) {
                onArtistSelected(artist);
              }
            },
            selectedColor: colorScheme.primary.withValues(
              alpha: _selectedChipAlpha,
            ),
            labelStyle: const TextStyle(fontWeight: FontWeight.w400),
            visualDensity: VisualDensity.compact,
            padding: ArtistListViewWidget._chipPadding,
            side: BorderSide(
              color: isSelected
                  ? colorScheme.primary
                  : colorScheme.outline.withValues(
                      alpha: ArtistListViewWidget._unselectedBorderAlpha,
                    ),
              width: isSelected
                  ? ArtistListViewWidget._selectedBorderWidth
                  : ArtistListViewWidget._unselectedBorderWidth,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(
                ArtistListViewWidget._chipBorderRadius,
              ),
              side: BorderSide(
                color: isSelected
                    ? colorScheme.primary
                    : colorScheme.outline.withValues(
                        alpha: ArtistListViewWidget._unselectedBorderAlpha,
                      ),
                width: isSelected
                    ? ArtistListViewWidget._selectedBorderWidth
                    : ArtistListViewWidget._unselectedBorderWidth,
              ),
            ),
            checkmarkColor: colorScheme.primary,
          );
        }).toList(),
      ),
    );
  }

  List<String> _getUniqueArtists() {
    final Set<String> artistSet = songs.map((Song song) => song.author).toSet();
    return artistSet.toList();
  }

  int _getSongCountForArtist(String artist) {
    return songs.where((Song song) => song.author == artist).length;
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
      return const Center(child: Text(_emptySongListMessage));
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
      return const Center(child: Text(_emptySongListMessage));
    }

    return ListView(
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: ArtistListViewWidget(
            songs: songs,
            selectedArtist: selectedArtist,
            onArtistSelected: onArtistSelected,
          ),
        ),
        ..._buildArtistSongTiles(),
      ],
    );
  }

  List<Widget> _buildArtistSongTiles() {
    if (selectedArtist.isEmpty) {
      return const <Widget>[];
    }

    final List<Song> artistSongs = _getSongsByArtist(selectedArtist);

    if (artistSongs.isEmpty) {
      return [const Center(child: Text(_emptySongListMessage))];
    }

    final List<Song> sortedSongs = _getSortedSongs(artistSongs);

    return <Widget>[
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: sortedSongs.length,
          itemBuilder: (BuildContext context, int index) {
            return SongTileWidget(
              song: sortedSongs[index],
              onTap: onSongTap,
            );
          },
        ),
      ),
    ];
  }

  List<Song> _getSortedSongs(List<Song> songList) {
    final List<Song> sorted = List<Song>.from(songList);
    sorted.sort((Song a, Song b) => a.name.compareTo(b.name));
    return sorted;
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
final class SongsWidget extends StatelessWidget {
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

  /// Creates a new [SongsWidget].
  const SongsWidget({
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
      return SongListModeWidget(songs: songs, onSongTap: onSongTap);
    }

    return ArtistModeWidget(
      songs: songs,
      selectedArtist: selectedArtist,
      onArtistSelected: onArtistSelected,
      onSongTap: onSongTap,
    );
  }
}
