/// A sound input of the device (built-in microphone, headset, USB interface…).
final class Microphone {
  /// Id the system selects it by.
  final String id;

  /// Name shown to the user.
  final String label;

  /// Creates a [Microphone].
  const Microphone({required this.id, required this.label});
}
