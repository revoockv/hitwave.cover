/// What can go wrong with songs and covers; the presentation layer turns it into text.
enum SongFailure {
  /// Nobody is signed in and the guest mode is off.
  notAuthenticated,

  /// The song could not be added.
  addSong,

  /// Songs from a backup or another device could not be added.
  addSongs,

  /// The song could not be changed.
  updateSong,

  /// The scroll speed could not be saved.
  updateSpeed,

  /// The lead-in could not be saved.
  updateLeadIn,

  /// The lyrics could not be saved.
  updateLyrics,

  /// The song could not be deleted.
  deleteSong,

  /// Not all songs of this device moved to the account.
  transfer,

  /// The choice to keep the songs on this device could not be remembered.
  keepLocal,

  /// The cover could not be added.
  addCover,

  /// The cover could not be changed.
  updateCover,

  /// The cover could not be deleted.
  deleteCover,
}
