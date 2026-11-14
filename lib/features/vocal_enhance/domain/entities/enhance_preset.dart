/// Ready-made settings of the vocal chain; any setting can be changed on top of a preset.
enum EnhancePreset {
  /// Clean and open: balances the tone, evens out only the peaks and keeps the pauses quiet.
  natural,

  /// Closer and denser: stronger noise reduction and de-essing, more compression, louder.
  studio,

  /// No colouring: only the loudness and the limiter, to compare with the raw take.
  loudness,

  /// The first sound of the app: a fixed EQ and a compressor that lifts the quiet parts.
  classic,
}
