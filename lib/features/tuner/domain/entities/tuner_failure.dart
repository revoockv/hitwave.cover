/// What can go wrong with the tuner; the presentation layer turns it into text.
enum TunerFailure {
  /// The app may not use the microphone.
  microphonePermission,

  /// The microphone could not be opened (busy with a take, or not available on this platform).
  start,
}
