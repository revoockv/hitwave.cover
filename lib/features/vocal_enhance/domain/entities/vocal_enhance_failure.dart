/// What can go wrong with measuring or enhancing a take; the presentation layer turns it into text.
enum VocalEnhanceFailure {
  /// The audio engine does not run on this platform.
  unavailable,

  /// The take could not be measured.
  analyze,

  /// The take could not be enhanced.
  enhance,

  /// The enhanced take would overwrite the original one.
  samePath,

  /// The enhanced take is not a `.wav` file.
  notWav,

  /// The lead-in before the singing is negative.
  negativeLeadIn,
}
