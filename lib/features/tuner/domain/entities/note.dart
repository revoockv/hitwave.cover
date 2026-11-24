import 'dart:math' as math;

/// A note of the equal-tempered scale (A4 = 440 Hz), by its MIDI number.
final class Note {
  static const int _a4Midi = 69;
  static const double _a4Hertz = 440;
  static const int _notesPerOctave = 12;
  static const double _centsPerSemitone = 100;
  static const int _octaveOffset = 1;
  static const List<String> _names = <String>['C', 'C#', 'D', 'D#', 'E', 'F', 'F#', 'G', 'G#', 'A', 'A#', 'B'];

  /// E1, the lowest string of a bass.
  static const Note e1 = Note(28);

  /// A1.
  static const Note a1 = Note(33);

  /// D2.
  static const Note d2 = Note(38);

  /// G2.
  static const Note g2 = Note(43);

  /// E2, the lowest string of a guitar.
  static const Note e2 = Note(40);

  /// A2.
  static const Note a2 = Note(45);

  /// D3.
  static const Note d3 = Note(50);

  /// G3, the lowest string of a violin.
  static const Note g3 = Note(55);

  /// B3.
  static const Note b3 = Note(59);

  /// C4, middle C.
  static const Note c4 = Note(60);

  /// D4.
  static const Note d4 = Note(62);

  /// E4.
  static const Note e4 = Note(64);

  /// G4.
  static const Note g4 = Note(67);

  /// A4, 440 Hz.
  static const Note a4 = Note(69);

  /// E5.
  static const Note e5 = Note(76);

  /// The MIDI number (A4 = 69, E2 = 40).
  final int midi;

  /// Creates the note with the MIDI number [midi].
  const Note(this.midi);

  /// The note nearest to [hertz].
  factory Note.nearest(double hertz) => Note(_semitonesFromA4(hertz).round() + _a4Midi);

  /// The name without the octave: `E`, `F#`.
  String get name => _names[midi % _notesPerOctave];

  /// The octave in scientific notation: E2 is the lowest string of a guitar.
  int get octave => midi ~/ _notesPerOctave - _octaveOffset;

  /// The frequency in hertz.
  double get hertz => _a4Hertz * math.pow(2, (midi - _a4Midi) / _notesPerOctave);

  /// How far [hertz] is from this note in cents: below 0 is too low, above 0 too high.
  double centsOf(double hertz) => (_semitonesFromA4(hertz) - (midi - _a4Midi)) * _centsPerSemitone;

  static double _semitonesFromA4(double hertz) => _notesPerOctave * math.log(hertz / _a4Hertz) / math.ln2;

  @override
  bool operator ==(Object other) => other is Note && other.midi == midi;

  @override
  int get hashCode => midi.hashCode;
}
