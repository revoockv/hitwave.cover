/// Where the tuner hears the pitch: the microphone, analyzed piece by piece.
///
/// Every method throws the platform exception when the microphone fails.
abstract interface class PitchDataSource {
  /// Whether the app may use the microphone; asks the user the first time.
  Future<bool> hasPermission();

  /// Starts listening: the stream gives the heard pitch in hertz several times a second, `null`
  /// while nothing clear sounds.
  Future<Stream<double?>> listen();

  /// Stops listening.
  Future<void> stop();

  /// Releases the microphone for good.
  Future<void> dispose();
}
