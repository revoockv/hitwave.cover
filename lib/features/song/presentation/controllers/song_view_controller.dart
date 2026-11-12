import 'package:flutter/foundation.dart' show ValueNotifier;

/// View mode for the song list display.
enum SongViewMode {
  /// Show all songs in a vertical list sorted by name.
  list,

  /// Show songs grouped by artist in horizontal lists.
  artist,
}

/// Tabs of the home page under the practice overview.
enum HomeTab {
  /// The songs.
  songs,

  /// Every recorded cover.
  covers,
}

/// Manages the home tab, the song view mode and selected artist state.
///
/// A Flutter-style controller: [homeTabController], [viewModeController] and
/// [selectedArtistController] hold the UI state, the page watches them.
final class SongViewController {
  /// Selected artist when none is chosen.
  static const String _noArtist = '';

  /// The tab shown under the practice overview.
  final ValueNotifier<HomeTab> homeTabController;

  /// The current view mode for displaying songs.
  final ValueNotifier<SongViewMode> viewModeController;

  /// The currently selected artist name, or empty string if no artist is selected.
  final ValueNotifier<String> selectedArtistController;

  /// Creates a new [SongViewController] with default values.
  SongViewController()
    : homeTabController = ValueNotifier<HomeTab>(HomeTab.songs),
      viewModeController = ValueNotifier<SongViewMode>(SongViewMode.artist),
      selectedArtistController = ValueNotifier<String>(_noArtist);

  /// Shows [tab].
  void selectTab(HomeTab tab) {
    homeTabController.value = tab;
  }

  /// Switches the view mode and clears the selected artist.
  void toggleViewMode() {
    viewModeController.value = viewModeController.value == SongViewMode.list ? SongViewMode.artist : SongViewMode.list;
    selectedArtistController.value = _noArtist;
  }

  /// Selects an artist by name.
  void selectArtist(String artist) {
    selectedArtistController.value = artist;
  }

  /// Clears the selected artist and goes back to the artist list.
  void clearArtist() {
    selectedArtistController.value = _noArtist;
  }

  /// Disposes the underlying [ValueNotifier] instances.
  void dispose() {
    homeTabController.dispose();
    viewModeController.dispose();
    selectedArtistController.dispose();
  }
}
