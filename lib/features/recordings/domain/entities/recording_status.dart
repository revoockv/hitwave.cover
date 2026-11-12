/// State of the automatic enhancement of a recording.
enum RecordingStatus {
  /// The engine is enhancing the take (or will once the running one finishes).
  enhancing,

  /// The enhanced file is ready.
  enhanced,

  /// The enhancement failed; the raw take is still there and can be enhanced again.
  enhanceFailed,
}
