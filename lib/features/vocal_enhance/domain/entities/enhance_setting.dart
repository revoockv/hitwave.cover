/// One setting of the vocal chain by its engine name (`air_db`, `noise_reduction_db`) and its value.
final class EnhanceSetting {
  /// The engine name of the setting.
  final String name;

  /// Its value; a switch is 1 (on) or 0 (off).
  final double value;

  /// Creates an [EnhanceSetting].
  const EnhanceSetting(this.name, this.value);

  @override
  bool operator ==(Object other) => other is EnhanceSetting && other.name == name && other.value == value;

  @override
  int get hashCode => Object.hash(name, value);
}
