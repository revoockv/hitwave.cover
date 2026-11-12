import '../../domain/entities/microphone.dart';

/// The microphone. May throw; the repository converts errors to failures.
abstract interface class RecorderDataSource {
  /// The sound inputs of the device.
  Future<List<Microphone>> microphones();

  /// Whether the app may use the microphone; asks the user when not decided yet.
  Future<bool> hasPermission();

  /// Starts recording an uncompressed 48 kHz mono WAV file to [path] from [microphoneId] (the
  /// system input when `null` or not connected), with every system effect (gain control, noise
  /// suppression, echo cancellation) off.
  Future<void> start(String path, {String? microphoneId});

  /// Stops recording and returns the path of the file, or `null` when nothing was recorded.
  Future<String?> stop();

  /// The current input level, 0.0 (silence) – 1.0 (full scale).
  Future<double> level();

  /// Releases the microphone.
  Future<void> dispose();
}
