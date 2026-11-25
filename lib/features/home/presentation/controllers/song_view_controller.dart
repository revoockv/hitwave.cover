import 'package:flutter/widgets.dart' show TextEditingController, ValueNotifier;

import '../../../song/domain/entities/song_sort.dart';

/// UI state of the song list: the order and the search of the songs and the selected artist.
///
/// A Flutter-style controller: the page watches its notifiers and text controllers.
final class SongViewController {
  /// Selected artist when none is chosen.
  static const String _noArtist = '';

  /// Order of the songs tab.
  final ValueNotifier<SongSort> songSortController = ValueNotifier<SongSort>(SongSort.artists);

  /// The currently selected artist name, or empty string if no artist is selected.
  final ValueNotifier<String> selectedArtistController = ValueNotifier<String>(_noArtist);

  /// Search text of the songs tab.
  final TextEditingController songSearchController = TextEditingController();

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
    songSortController.dispose();
    selectedArtistController.dispose();
    songSearchController.dispose();
  }
}
