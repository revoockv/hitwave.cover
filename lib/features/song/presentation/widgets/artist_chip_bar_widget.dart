import 'package:flutter/material.dart';

import '../../../../core/presentation/theme.dart';

/// One-line, horizontally scrolling bar of artist chips.
///
/// Takes a single row however many artists there are. The selected chip is
/// scrolled to the middle of the bar; the leading button calls [onShowAllArtists].
final class ArtistChipBarWidget extends StatefulWidget {
  /// Artists, already sorted.
  final List<String> artists;

  /// The selected artist.
  final String selectedArtist;

  /// Called when a chip is tapped.
  final void Function(String artist) onArtistSelected;

  /// Called when the "all artists" button is pressed.
  final VoidCallback onShowAllArtists;

  /// Creates a new [ArtistChipBarWidget].
  const ArtistChipBarWidget({
    required this.artists,
    required this.selectedArtist,
    required this.onArtistSelected,
    required this.onShowAllArtists,
    super.key,
  });

  @override
  State<ArtistChipBarWidget> createState() => _ArtistChipBarWidgetState();
}

class _ArtistChipBarWidgetState extends State<ArtistChipBarWidget> {
  /// Height of the bar.
  static const double _barHeight = 56;

  /// Where the selected chip lands in the bar: the middle.
  static const double _centerAlignment = 0.5;

  /// Duration of scrolling to the selected chip.
  static const Duration _scrollDuration = Duration(milliseconds: 250);

  /// Tooltip of the "all artists" button.
  static const String _allArtistsTooltip = 'Усі виконавці';

  final Map<String, GlobalKey> _chipKeys = <String, GlobalKey>{};

  @override
  void initState() {
    super.initState();
    _scheduleScrollToSelected();
  }

  @override
  void didUpdateWidget(ArtistChipBarWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selectedArtist != widget.selectedArtist) {
      _scheduleScrollToSelected();
    }
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: _barHeight,
      child: Row(
        children: <Widget>[
          IconButton(
            tooltip: _allArtistsTooltip,
            icon: const Icon(Icons.format_list_bulleted),
            onPressed: widget.onShowAllArtists,
          ),
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.only(right: AppTheme.spacingMedium),
              child: Row(
                spacing: AppTheme.spacingSmall,
                children: <Widget>[
                  for (final String artist in widget.artists)
                    ChoiceChip(
                      key: _chipKeys.putIfAbsent(artist, GlobalKey.new),
                      label: Text(artist),
                      selected: artist == widget.selectedArtist,
                      onSelected: (bool selected) => _onChipSelected(artist, selected),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _onChipSelected(String artist, bool selected) {
    if (selected) {
      widget.onArtistSelected(artist);
    }
  }

  void _scheduleScrollToSelected() {
    WidgetsBinding.instance.addPostFrameCallback(_scrollToSelected);
  }

  void _scrollToSelected(Duration _) {
    final BuildContext? chipContext = _chipKeys[widget.selectedArtist]?.currentContext;
    if (!mounted || chipContext == null) {
      return;
    }
    Scrollable.ensureVisible(chipContext, alignment: _centerAlignment, duration: _scrollDuration);
  }
}
