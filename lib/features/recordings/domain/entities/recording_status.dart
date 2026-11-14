/// State of the enhancement of a recording; the user starts it from the card of the take.
enum RecordingStatus {
  /// Saved as recorded; not enhanced yet.
  recorded,

  /// The engine is enhancing the take (or will once the running one finishes).
  enhancing,

  /// The enhanced file is ready.
  enhanced,

  /// The enhancement failed; the raw take is still there and can be enhanced again.
  enhanceFailed,
}
