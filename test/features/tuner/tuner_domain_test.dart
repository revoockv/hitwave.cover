import 'package:flutter_test/flutter_test.dart';
import 'package:hitwave.cover/features/tuner/domain/entities/instrument.dart';
import 'package:hitwave.cover/features/tuner/domain/entities/note.dart';
import 'package:hitwave.cover/features/tuner/domain/entities/tuner_reading.dart';

void main() {
  test('notes have their names, octaves and frequencies', () {
    expect(Note.a4.hertz, closeTo(440, 1e-9));
    expect(Note.e2.hertz, closeTo(82.41, 0.01));
    expect('${Note.e2.name}${Note.e2.octave}', 'E2');
    expect('${const Note(61).name}${const Note(61).octave}', 'C#4');
    expect(Note.nearest(445), Note.a4);
    expect(Note.a4.centsOf(440 * 1.0057929), closeTo(10, 0.01));
    expect(Note.a4.centsOf(435), lessThan(0));
  });

  test('the strings of every instrument from the lowest', () {
    String names(Instrument instrument) =>
        instrument.strings.map((Note note) => '${note.name}${note.octave}').join(' ');

    expect(names(Instrument.guitar), 'E2 A2 D3 G3 B3 E4');
    expect(names(Instrument.ukulele), 'G4 C4 E4 A4');
    expect(names(Instrument.bass), 'E1 A1 D2 G2');
    expect(names(Instrument.violin), 'G3 D4 A4 E5');
    expect(Instrument.chromatic.strings, isEmpty);
  });

  test('a reading aims at the nearest string, also far from it', () {
    final TunerReading low = TunerReading.of(104, Instrument.guitar);
    final TunerReading sharp = TunerReading.of(111, Instrument.guitar);
    final TunerReading ukulele = TunerReading.of(390, Instrument.ukulele);

    expect(low.target, Note.a2);
    expect(low.cents, lessThan(-50));
    expect(low.isInTune, isFalse);
    expect(sharp.target, Note.a2);
    expect(sharp.cents, closeTo(15.67, 0.1));
    expect(ukulele.target, Note.g4);
    expect(TunerReading.of(Note.d3.hertz, Instrument.guitar).isInTune, isTrue);
  });

  test('chromatic aims at the nearest note of the scale', () {
    final TunerReading reading = TunerReading.of(277, Instrument.chromatic);

    expect('${reading.target.name}${reading.target.octave}', 'C#4');
    expect(reading.isInTune, isTrue);
  });
}
