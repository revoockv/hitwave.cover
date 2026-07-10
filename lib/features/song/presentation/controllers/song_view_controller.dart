import 'package:flutter/foundation.dart' show ValueNotifier;
import 'package:hitwave.cover/features/song/presentation/pages/home_page.dart';

/// Manages the song view mode and selected artist state.
///
/// Exposes [viewMode] and [selectedArtist] as [ValueNotifier] instances
/// so that UI can reactively build using [ValueListenableBuilder].
final class SongViewController {
  /// The current view mode for displaying songs.
  final ValueNotifier<SongViewMode> viewMode;

  /// The currently selected artist name, or empty string if no artist is selected.
  final ValueNotifier<String> selectedArtist;

  /// Creates a new [SongViewManager] with default values.
  SongViewController()
      : viewMode = ValueNotifier<SongViewMode>(SongViewMode.artist),
        selectedArtist = ValueNotifier<String>('');

  /// Switches the view mode and clears the selected artist.
  void toggleViewMode() {
    viewMode.value = viewMode.value == SongViewMode.list
        ? SongViewMode.artist
        : SongViewMode.list;
    selectedArtist.value = '';
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
