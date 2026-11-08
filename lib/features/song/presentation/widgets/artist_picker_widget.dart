import 'package:flutter/material.dart';

import '../../../../core/presentation/theme.dart';
import 'artist_tile_widget.dart';

/// Compact list of artists with song counts and a search field.
///
/// One line per artist, so many artists fit on a phone screen. The search
/// field appears when there are more than [_searchThreshold] artists.
/// Tapping an artist calls [onArtistSelected].
final class ArtistPickerWidget extends StatefulWidget {
  /// Artists, already sorted.
  final List<String> artists;

  /// Number of songs of each artist.
  final Map<String, int> songCounts;

  /// Called when an artist is tapped.
  final void Function(String artist) onArtistSelected;

  /// Creates a new [ArtistPickerWidget].
  const ArtistPickerWidget({
    required this.artists,
    required this.songCounts,
    required this.onArtistSelected,
    super.key,
  });

  @override
  State<ArtistPickerWidget> createState() => _ArtistPickerWidgetState();
}

class _ArtistPickerWidgetState extends State<ArtistPickerWidget> {
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

  late final TextEditingController _searchController;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bool showSearch = widget.artists.length > _searchThreshold;

    return Column(
      children: <Widget>[
        if (showSearch)
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppTheme.spacingMedium,
              AppTheme.spacingSmall,
              AppTheme.spacingMedium,
              AppTheme.spacingSmall,
            ),
            child: TextField(
              controller: _searchController,
              textInputAction: TextInputAction.search,
              decoration: InputDecoration(
                hintText: _searchHint,
                prefixIcon: const Icon(Icons.search),
                suffixIcon: ValueListenableBuilder<TextEditingValue>(
                  valueListenable: _searchController,
                  builder: (BuildContext context, TextEditingValue value, Widget? child) {
                    if (value.text.isEmpty) {
                      return const SizedBox.shrink();
                    }
                    return IconButton(
                      tooltip: _clearTooltip,
                      icon: const Icon(Icons.close),
                      onPressed: _onClearPressed,
                    );
                  },
                ),
              ),
            ),
          ),
        Expanded(
          child: ValueListenableBuilder<TextEditingValue>(
            valueListenable: _searchController,
            builder: (BuildContext context, TextEditingValue value, Widget? child) {
              final String query = value.text.trim().toLowerCase();
              final List<String> artists = query.isEmpty
                  ? widget.artists
                  : widget.artists.where((String artist) => artist.toLowerCase().contains(query)).toList();

              if (artists.isEmpty) {
                return const Center(child: Text(_nothingFound));
              }

              return ListView.builder(
                keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
                padding: const EdgeInsets.only(bottom: _fabClearance),
                itemCount: artists.length,
                itemBuilder: (BuildContext context, int index) => ArtistTileWidget(
                  artist: artists[index],
                  songCount: widget.songCounts[artists[index]] ?? 0,
                  onTap: widget.onArtistSelected,
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  void _onClearPressed() {
    _searchController.clear();
  }
}
