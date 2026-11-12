/// Ready-made settings of the vocal chain; any setting can be changed on top of a preset.
enum EnhancePreset {
  /// Gentle cleanup: keeps the room and the dynamics, removes rumble and steady noise.
  natural,

  /// Close and polished: stronger noise reduction, more presence, tighter compression.
  studio,

  /// No colouring: only the loudness and the limiter, to compare with the raw take.
  loudness,
}
