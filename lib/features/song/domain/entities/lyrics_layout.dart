/// The screen the lyrics are read on: the scroll speed and the space above the lyrics are saved
/// for each one apart, since a phone and a big screen fit a different number of lines.
enum LyricsLayout {
  /// A phone.
  compact,

  /// A tablet, a desktop window.
  wide,
}
