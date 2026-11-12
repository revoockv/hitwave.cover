/// The microphone. May throw; the repository converts errors to failures.
abstract interface class RecorderDataSource {
  /// Whether the app may use the microphone; asks the user when not decided yet.
  Future<bool> hasPermission();

  /// Starts recording an uncompressed 48 kHz mono WAV file to [path], with every system
  /// effect (gain control, noise suppression, echo cancellation) off.
  Future<void> start(String path);

  /// Stops recording and returns the path of the file, or `null` when nothing was recorded.
  Future<String?> stop();

  /// The current input level, 0.0 (silence) – 1.0 (full scale).
  Future<double> level();

  /// Releases the microphone.
  Future<void> dispose();
}
