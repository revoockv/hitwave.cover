import 'package:flutter/widgets.dart' show TextEditingController, ValueNotifier;

/// View mode for the song list display.
enum SongViewMode {
  /// Show all songs in a vertical list.
  list,

  /// Show songs grouped by artist.
  artist,
}

/// Tabs of the bottom navigation of the home page.
enum HomeTab {
  /// Overview: mini statistics, the songs opened and the covers played last.
  home,

  /// The songs.
  songs,

  /// Every recorded cover.
  covers,

  /// The practice statistics.
  stats,
}

/// Order of the songs tab.
enum SongSort {
  /// By name, A to Z.
  name,

  /// The song opened last first.
  recent,

  /// The song with the most covers first.
  covers,

  /// Grouped by artist.
  artists,
}

/// UI state of the home page: the tab, the order and the search of the songs, the selected
/// artist and the search of the covers.
///
/// A Flutter-style controller: the page watches its notifiers and text controllers.
final class SongViewController {
  /// Selected artist when none is chosen.
  static const String _noArtist = '';

  /// The tab shown.
  final ValueNotifier<HomeTab> homeTabController = ValueNotifier<HomeTab>(HomeTab.home);

  /// Order of the songs tab.
  final ValueNotifier<SongSort> songSortController = ValueNotifier<SongSort>(SongSort.artists);

  /// The currently selected artist name, or empty string if no artist is selected.
  final ValueNotifier<String> selectedArtistController = ValueNotifier<String>(_noArtist);

  /// Search text of the songs tab.
  final TextEditingController songSearchController = TextEditingController();

  /// Search text of the covers tab.
  final TextEditingController coverSearchController = TextEditingController();

  /// Shows [tab].
  void selectTab(HomeTab tab) {
    homeTabController.value = tab;
  }

  /// Orders the songs by [sort] and clears the selected artist.
  void selectSort(SongSort sort) {
    songSortController.value = sort;
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

  /// Disposes the notifiers and text controllers.
  void dispose() {
    homeTabController.dispose();
    songSortController.dispose();
    selectedArtistController.dispose();
    songSearchController.dispose();
    coverSearchController.dispose();
  }
}
