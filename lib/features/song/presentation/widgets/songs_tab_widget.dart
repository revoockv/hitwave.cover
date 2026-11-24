import 'package:flutter/material.dart';
import '../../../recordings/domain/entities/cover_counts.dart';

import '../../../../core/presentation/l10n/app_translations.dart';
import '../../../../core/presentation/theme.dart';
import '../../domain/entities/song.dart';
import '../controllers/song_view_controller.dart';
import 'search_field_widget.dart';
import 'songs_widget.dart';

/// The songs tab: search, the order chips and the songs.
///
/// Gets the songs already found and ordered; knows nothing about use cases.
final class SongsTabWidget extends StatelessWidget {
  /// Whether the library has no songs at all.
  final bool isLibraryEmpty;

  /// The songs found, in the order to show.
  final List<Song> songs;

  /// Number of covers by song id.
  final CoverCounts coverCounts;

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
    required this.coverCounts,
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
    final Translations t = context.t;
    if (isLibraryEmpty) return EmptySongsWidget(onAddPressed: onAddPressed);
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
                    SearchFieldWidget(searchController: searchController, hint: t.song.searchSongs),
                    const SizedBox(height: AppTheme.spacingSmall),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: <Widget>[
                          for (final SongSort option in SongSort.values)
                            Padding(
                              padding: const EdgeInsets.only(right: AppTheme.spacingSmall),
                              child: ChoiceChip(
                                label: Text(_sortLabel(t, option)),
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
              ? Center(child: Text(t.common.nothingFound))
              : SongsWidget(
                  songs: songs,
                  coverCounts: coverCounts,
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

  static String _sortLabel(Translations t, SongSort sort) => switch (sort) {
    SongSort.artists => t.song.sort.artists,
    SongSort.name => t.song.sort.name,
    SongSort.recent => t.song.sort.recent,
    SongSort.covers => t.song.sort.covers,
  };
}
