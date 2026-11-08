import 'package:flutter/material.dart';
import 'package:watch_it/watch_it.dart';

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

  /// Hint of the search field.
  static const String _searchHint = 'Пошук виконавця';

  /// Tooltip of the clear button of the search field.
  static const String _clearTooltip = 'Очистити';

  /// Shown when no artist matches the search.
  static const String _nothingFound = 'Нічого не знайдено';

  /// Songs whose artists are listed.
  final List<Song> songs;

  /// Artist to highlight, or empty when none.
  final String selectedArtist;

  /// Called when an artist is tapped.
  final void Function(String artist) onArtistSelected;

  /// Creates a new [ArtistPickerWidget].
  const ArtistPickerWidget({required this.songs, required this.onArtistSelected, this.selectedArtist = '', super.key});

  @override
  Widget build(BuildContext context) {
    final TextEditingController search = createOnce(_createSearch, dispose: _disposeSearch);
    final String query = watch(search).value.text.trim().toLowerCase();

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
              controller: search,
              textInputAction: TextInputAction.search,
              decoration: InputDecoration(
                hintText: _searchHint,
                prefixIcon: const Icon(Icons.search),
                suffixIcon: query.isEmpty
                    ? null
                    : IconButton(tooltip: _clearTooltip, icon: const Icon(Icons.close), onPressed: search.clear),
              ),
            ),
          ),
        Expanded(
          child: artists.isEmpty
              ? const Center(child: Text(_nothingFound))
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

  static TextEditingController _createSearch() => TextEditingController();

  static void _disposeSearch(TextEditingController search) => search.dispose();

  static int _compareArtists(String a, String b) => a.toLowerCase().compareTo(b.toLowerCase());
}
