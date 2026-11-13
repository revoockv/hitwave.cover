import 'dart:typed_data';

/// Byte channel to the embedded Python program that runs the audio engine.
abstract interface class PythonEngineChannel {
  /// Messages the Python program sends (UTF-8 JSON events).
  Stream<Uint8List> get messages;

  /// Starts the Python program; [messages] receives its `ready` event when it listens.
  Future<void> start();

  /// Delivers [bytes] to the Python program; `false` while it is not listening yet.
  bool send(Uint8List bytes);

  /// Releases the channel.
  void close();
}
