/// View mode for the song list display.
enum SongViewMode {
  /// Show all songs in a vertical list.
  list,

  /// Show songs grouped by artist.
  artist,
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
