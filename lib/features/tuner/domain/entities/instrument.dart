import 'note.dart';

/// An instrument the tuner knows, with its strings in standard tuning from the lowest (thickest) one.
enum Instrument {
  /// Six-string guitar: E2 A2 D3 G3 B3 E4.
  guitar(<Note>[Note.e2, Note.a2, Note.d3, Note.g3, Note.b3, Note.e4]),

  /// Soprano, concert and tenor ukulele with a high G: G4 C4 E4 A4.
  ukulele(<Note>[Note.g4, Note.c4, Note.e4, Note.a4]),

  /// Four-string bass guitar: E1 A1 D2 G2.
  bass(<Note>[Note.e1, Note.a1, Note.d2, Note.g2]),

  /// Violin (and mandolin): G3 D4 A4 E5.
  violin(<Note>[Note.g3, Note.d4, Note.a4, Note.e5]),

  /// Any note: the tuner shows the nearest one of the scale.
  chromatic(<Note>[]);

  /// The strings in the order they are written in a tab, empty for [chromatic].
  final List<Note> strings;

  /// Creates an instrument with its [strings].
  const Instrument(this.strings);
}
