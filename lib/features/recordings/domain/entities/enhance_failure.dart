/// Why the enhancement of a take failed; the presentation layer turns it into text.
enum EnhanceFailure {
  /// The app stopped while the take was being enhanced.
  interrupted,

  /// The audio engine does not run on this platform.
  unavailable,

  /// The engine could not enhance the take.
  failed,
}
