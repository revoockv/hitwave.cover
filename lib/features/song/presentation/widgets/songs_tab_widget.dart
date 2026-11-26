import 'package:flutter/material.dart';

import '../../../../core/presentation/theme.dart';
import '../../domain/entities/song.dart';
import '../../domain/entities/song_sort.dart';
import 'artist_picker_widget.dart';
import 'search_field_widget.dart';
import 'song_tile_widget.dart';
import 'empty_songs_widget.dart';
import 'songs_widget.dart';

/// The texts of the songs tab and its lists.
final class SongListTexts {
  /// The texts of a song tile.
  final SongTileTexts tile;

  /// The texts of the empty library.
  final EmptySongsTexts empty;

  /// The texts of the artist list.
  final ArtistPickerTexts picker;

  /// Hint of the search field.
  final String searchHintText;

  /// Tooltip of the button that clears the search.
  final String clearTooltip;

  /// Shown when no song matches the search.
  final String nothingFoundText;

  /// The label of an order chip.
  final String Function(SongSort sort) sortLabelOf;

  /// Creates the texts.
  const SongListTexts({
    required this.tile,
    required this.empty,
    required this.picker,
    required this.searchHintText,
    required this.clearTooltip,
    required this.nothingFoundText,
    required this.sortLabelOf,
  });
}

/// The songs tab: search, the order chips and the songs.
///
/// Gets the songs already found and ordered; knows nothing about use cases.
final class SongsTabWidget extends StatelessWidget {
  /// Whether the library has no songs at all.
  final bool isLibraryEmpty;

  /// The songs found, in the order to show.
  final List<Song> songs;

  /// How many covers the song with an id has.
  final int Function(String songId) coverCountOf;

  /// The texts.
  final SongListTexts texts;

  /// The search text.
  final TextEditingController searchController;

  /// The chosen order.
  final SongSort sort;

  /// The selected artist in the artist order, or empty.
  final String selectedArtist;

  /// Called with the chosen order.
  final ValueChanged<SongSort> onSortSelected;

  /// Called with the chosen artist.
  final ValueChanged<String> onArtistSelected;

  /// Called when a song is tapped.
  final void Function(Song song) onSongTap;

  /// Called when "edit" is chosen for a song.
  final void Function(Song song) onSongEdit;

  /// Called when "delete" is chosen for a song.
  final void Function(Song song) onSongDelete;

  /// Called from the empty state to add the first song.
  final VoidCallback onAddPressed;

  /// Creates a new [SongsTabWidget].
  const SongsTabWidget({
    super.key,
    required this.isLibraryEmpty,
    required this.songs,
    required this.coverCountOf,
    required this.texts,
    required this.searchController,
    required this.sort,
    required this.selectedArtist,
    required this.onSortSelected,
    required this.onArtistSelected,
    required this.onSongTap,
    required this.onSongEdit,
    required this.onSongDelete,
    required this.onAddPressed,
  });

  @override
  Widget build(BuildContext context) {
    if (isLibraryEmpty) return EmptySongsWidget(texts: texts.empty, onAddPressed: onAddPressed);
    final bool isSearching = searchController.text.trim().isNotEmpty;
    final bool showsArtist = sort == SongSort.artists && selectedArtist.isNotEmpty && !isSearching;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        if (!showsArtist)
          Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: AppTheme.maxContentWidth),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppTheme.spacingMedium,
                  AppTheme.spacingSmall,
                  AppTheme.spacingMedium,
                  0,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    SearchFieldWidget(
                      searchController: searchController,
                      hintText: texts.searchHintText,
                      clearTooltip: texts.clearTooltip,
                    ),
                    const SizedBox(height: AppTheme.spacingSmall),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: <Widget>[
                          for (final SongSort option in SongSort.values)
                            Padding(
                              padding: const EdgeInsets.only(right: AppTheme.spacingSmall),
                              child: ChoiceChip(
                                label: Text(texts.sortLabelOf(option)),
                                selected: option == sort,
                                onSelected: (bool selected) => onSortSelected(option),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        Expanded(
          child: songs.isEmpty
              ? Center(child: Text(texts.nothingFoundText))
              : SongsWidget(
                  songs: songs,
                  coverCountOf: coverCountOf,
                  texts: texts,
                  viewMode: sort == SongSort.artists && !isSearching ? SongViewMode.artist : SongViewMode.list,
                  selectedArtist: selectedArtist,
                  onArtistSelected: onArtistSelected,
                  onSongTap: onSongTap,
                  onSongEdit: onSongEdit,
                  onSongDelete: onSongDelete,
                  onAddPressed: onAddPressed,
                ),
        ),
      ],
    );
  }
}
