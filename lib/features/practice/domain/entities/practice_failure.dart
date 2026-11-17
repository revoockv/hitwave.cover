/// What can go wrong with the practice; the presentation layer turns it into text.
enum PracticeFailure {
  /// A practice session could not be saved.
  saveSession,

  /// Practice sessions from a backup or another device could not be added.
  importSessions,

  /// A practice session could not be deleted.
  deleteSession,

  /// The practice could not be cleared.
  clear,
}
