import 'package:flutter/material.dart';

import '../../../../core/presentation/theme.dart';
import '../../domain/entities/song.dart';
import 'artist_tile_widget.dart';

/// The texts of [ArtistPickerWidget].
final class ArtistPickerTexts {
  /// Hint of the search field.
  final String searchHintText;

  /// Tooltip of the button that clears the search.
  final String clearTooltip;

  /// Shown when no artist matches the search.
  final String nothingFoundText;

  /// The number of an artist's songs as text ("3 songs").
  final String Function(int count) songCountText;

  /// Creates the texts.
  const ArtistPickerTexts({
    required this.searchHintText,
    required this.clearTooltip,
    required this.nothingFoundText,
    required this.songCountText,
  });
}

/// Compact list of the artists of [songs] with song counts and a search field.
///
/// One line per artist, so many artists fit on a phone screen. The search field appears when there are more than
/// [_searchThreshold] artists. Tapping an artist calls [onArtistSelected]; [selectedArtist] is highlighted.
///
/// Dumb: it owns only its search field's controller (plain Flutter) and filters while the text changes.
final class ArtistPickerWidget extends StatefulWidget {
  /// Songs whose artists are listed.
  final List<Song> songs;

  /// Artist to highlight, or empty when none.
  final String selectedArtist;

  /// The texts.
  final ArtistPickerTexts texts;

  /// Called when an artist is tapped.
  final void Function(String artist) onArtistSelected;

  /// Creates a new [ArtistPickerWidget].
  const ArtistPickerWidget({
    required this.songs,
    required this.texts,
    required this.onArtistSelected,
    this.selectedArtist = '',
    super.key,
  });

  @override
  State<ArtistPickerWidget> createState() => _ArtistPickerWidgetState();
}

final class _ArtistPickerWidgetState extends State<ArtistPickerWidget> {
  /// The search field appears above this many artists.
  static const int _searchThreshold = 6;

  /// Bottom padding so the last tile is not hidden by the floating button.
  static const double _fabClearance = 96;

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
    final List<_ArtistCount> allArtists = _artistsOf(widget.songs);
    return Column(
      children: <Widget>[
        if (allArtists.length > _searchThreshold)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppTheme.spacingMedium, vertical: AppTheme.spacingSmall),
            child: ValueListenableBuilder<TextEditingValue>(
              valueListenable: _searchController,
              builder: (BuildContext context, TextEditingValue value, Widget? child) => TextField(
                controller: _searchController,
                textInputAction: TextInputAction.search,
                decoration: InputDecoration(
                  hintText: widget.texts.searchHintText,
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: value.text.isEmpty
                      ? null
                      : IconButton(
                          tooltip: widget.texts.clearTooltip,
                          icon: const Icon(Icons.close),
                          onPressed: _searchController.clear,
                        ),
                ),
              ),
            ),
          ),
        Expanded(
          child: ValueListenableBuilder<TextEditingValue>(
            valueListenable: _searchController,
            builder: (BuildContext context, TextEditingValue value, Widget? child) {
              final String query = value.text.trim().toLowerCase();
              final List<_ArtistCount> artists = query.isEmpty
                  ? allArtists
                  : allArtists.where((_ArtistCount artist) => artist.name.toLowerCase().contains(query)).toList();
              if (artists.isEmpty) return Center(child: Text(widget.texts.nothingFoundText));
              return ListView.builder(
                keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
                padding: const EdgeInsets.only(bottom: _fabClearance),
                itemCount: artists.length,
                itemBuilder: (BuildContext context, int index) => ArtistTileWidget(
                  artist: artists[index].name,
                  songCountText: widget.texts.songCountText(artists[index].songs),
                  selected: artists[index].name == widget.selectedArtist,
                  onTap: widget.onArtistSelected,
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  /// The artists of [songs] with their song counts, A to Z.
  static List<_ArtistCount> _artistsOf(List<Song> songs) {
    final List<_ArtistCount> artists = <_ArtistCount>[];
    for (final Song song in songs) {
      final int index = artists.indexWhere((_ArtistCount artist) => artist.name == song.author);
      if (index < 0) {
        artists.add(_ArtistCount(song.author, 1));
      } else {
        artists[index] = _ArtistCount(song.author, artists[index].songs + 1);
      }
    }
    return artists..sort(_compareArtists);
  }

  static int _compareArtists(_ArtistCount a, _ArtistCount b) => a.name.toLowerCase().compareTo(b.name.toLowerCase());
}

/// An artist and how many songs it has.
final class _ArtistCount {
  final String name;

  final int songs;

  const _ArtistCount(this.name, this.songs);
}
