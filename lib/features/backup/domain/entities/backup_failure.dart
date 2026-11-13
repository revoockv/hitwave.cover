/// What can go wrong with a backup; the presentation layer turns it into text.
enum BackupFailure {
  /// The songs could not be exported.
  exportSongs,

  /// The songs could not be imported.
  importSongs,
}
