/// What to do with a song of a backup that is already in the library.
enum ImportChoice {
  /// Put the lyrics, album and speeds of the backup into the song in the library; its covers
  /// and takes stay.
  replace,

  /// Add the song of the backup next to the one in the library, under a name with a number.
  keepBoth,

  /// Leave the song in the library as it is and do not import this one (nor its takes).
  skip,
}
