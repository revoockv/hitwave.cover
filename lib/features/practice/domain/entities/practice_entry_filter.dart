/// Which items of the practice timeline are shown.
enum PracticeEntryFilter {
  /// Every session and every take.
  all,

  /// Only the sessions without takes.
  practiceOnly,

  /// Only the sessions with takes, and the takes outside every session.
  withTakes,
}
