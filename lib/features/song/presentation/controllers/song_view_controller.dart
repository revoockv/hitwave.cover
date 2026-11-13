import 'package:flutter/foundation.dart' show ValueNotifier;

/// View mode for the song list display.
enum SongViewMode {
  /// Show all songs in a vertical list sorted by name.
  list,

  /// Show songs grouped by artist in horizontal lists.
  artist,
}

/// Manages the song view mode and selected artist state.
///
/// Exposes [viewMode] and [selectedArtist] as [ValueNotifier] instances
/// so that UI can reactively build using [ValueListenableBuilder].
final class SongViewController {
  /// Selected artist when none is chosen.
  static const String _noArtist = '';

  /// The current view mode for displaying songs.
  final ValueNotifier<SongViewMode> viewMode;

  /// The currently selected artist name, or empty string if no artist is selected.
  final ValueNotifier<String> selectedArtist;

  /// Creates a new [SongViewController] with default values.
  SongViewController()
      : viewMode = ValueNotifier<SongViewMode>(SongViewMode.artist),
        selectedArtist = ValueNotifier<String>(_noArtist);

  /// Switches the view mode and clears the selected artist.
  void toggleViewMode() {
    viewMode.value = viewMode.value == SongViewMode.list
        ? SongViewMode.artist
        : SongViewMode.list;
    selectedArtist.value = _noArtist;
  }

  /// Selects an artist by name.
  void selectArtist(String artist) {
    selectedArtist.value = artist;
  }

  /// Disposes the underlying [ValueNotifier] instances.
  void dispose() {
    viewMode.dispose();
    selectedArtist.dispose();
  }
}
