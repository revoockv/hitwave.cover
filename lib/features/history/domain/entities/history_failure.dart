/// What can go wrong with the history; the presentation layer turns it into text.
enum HistoryFailure {
  /// The history could not be saved.
  save,

  /// The history could not be cleared.
  clear,
}
