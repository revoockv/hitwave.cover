import 'package:flutter/material.dart';
import 'package:watch_it/watch_it.dart';

import '../../../../core/presentation/l10n/app_translations.dart';
import '../../../../core/presentation/theme.dart';
import '../../domain/entities/song.dart';
import 'artist_tile_widget.dart';

/// Compact list of the artists of [songs] with song counts and a search field.
///
/// One line per artist, so many artists fit on a phone screen. The search
/// field appears when there are more than [_searchThreshold] artists.
/// Tapping an artist calls [onArtistSelected]; [selectedArtist] is highlighted.
final class ArtistPickerWidget extends WatchingWidget {
  /// The search field appears above this many artists.
  static const int _searchThreshold = 6;

  /// Bottom padding so the last tile is not hidden by the floating button.
  static const double _fabClearance = 96;

  /// Songs whose artists are listed.
  final List<Song> songs;

  /// Artist to highlight, or empty when none.
  final String selectedArtist;

  /// Called when an artist is tapped.
  final void Function(String artist) onArtistSelected;

  /// Creates a new [ArtistPickerWidget].
  const ArtistPickerWidget({required this.songs, required this.onArtistSelected, this.selectedArtist = '', super.key});

  /// The search text as matched: trimmed, lower case — not the cursor, so moving it does not rebuild.
  static String _queryOf(TextEditingController searchController) => searchController.text.trim().toLowerCase();

  @override
  Widget build(BuildContext context) {
    final Translations t = context.t;
    final TextEditingController searchController = createOnce(
      _createSearchController,
      dispose: _disposeSearchController,
    );
    final String query = watchPropertyValue(_queryOf, target: searchController);

    final Map<String, int> songCounts = <String, int>{};
    for (final Song song in songs) {
      songCounts[song.author] = (songCounts[song.author] ?? 0) + 1;
    }
    final List<String> allArtists = songCounts.keys.toList()..sort(_compareArtists);
    final List<String> artists = query.isEmpty
        ? allArtists
        : allArtists.where((String artist) => artist.toLowerCase().contains(query)).toList();

    return Column(
      children: <Widget>[
        if (allArtists.length > _searchThreshold)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppTheme.spacingMedium, vertical: AppTheme.spacingSmall),
            child: TextField(
              controller: searchController,
              textInputAction: TextInputAction.search,
              decoration: InputDecoration(
                hintText: t.song.artistSearch,
                prefixIcon: const Icon(Icons.search),
                suffixIcon: query.isEmpty
                    ? null
                    : IconButton(
                        tooltip: t.common.clear,
                        icon: const Icon(Icons.close),
                        onPressed: searchController.clear,
                      ),
              ),
            ),
          ),
        Expanded(
          child: artists.isEmpty
              ? Center(child: Text(t.common.nothingFound))
              : ListView.builder(
                  keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
                  padding: const EdgeInsets.only(bottom: _fabClearance),
                  itemCount: artists.length,
                  itemBuilder: (BuildContext context, int index) => ArtistTileWidget(
                    artist: artists[index],
                    songCount: songCounts[artists[index]] ?? 0,
                    selected: artists[index] == selectedArtist,
                    onTap: onArtistSelected,
                  ),
                ),
        ),
      ],
    );
  }

  static TextEditingController _createSearchController() => TextEditingController();

  static void _disposeSearchController(TextEditingController searchController) => searchController.dispose();

  static int _compareArtists(String a, String b) => a.toLowerCase().compareTo(b.toLowerCase());
}
