import 'package:flutter_test/flutter_test.dart';
import 'package:hitwave.cover/features/song/domain/entities/lyrics_chord.dart';

void main() {
  List<String> chordsOf(String lyrics) => LyricsChord.findAll(lyrics).map((LyricsChord chord) => chord.text).toList();

  test('every chord of a chord line, with bars, repeats and positions', () {
    expect(chordsOf('       E             Am           E'), <String>['E', 'Am', 'E']);
    expect(chordsOf('| G Em | Am G || Bbdim7 ||'), <String>['G', 'Em', 'Am', 'G', 'Bbdim7']);
    expect(chordsOf('   A(V) C#m(IV) F G#(IV) G(III)  (2)'), <String>['A(V)', 'C#m(IV)', 'F', 'G#(IV)', 'G(III)']);
    expect(chordsOf('E               G#m **'), <String>['E', 'G#m']);
    expect(chordsOf('Cmaj7 D7/F# AmM7 Emadd9 A7sus4 Hm'), <String>['Cmaj7', 'D7/F#', 'AmM7', 'Emadd9', 'A7sus4', 'Hm']);
    expect(chordsOf('D7sus C7sus F7sus D7sus4 C9sus G7add'), <String>['D7sus', 'C7sus', 'F7sus', 'D7sus4', 'C9sus', 'G7add']);
  });

  test('a run of chords before or inside words', () {
    expect(chordsOf('C#m Am Коли ти смієшся, тобто радієш,'), <String>['C#m', 'Am']);
    expect(chordsOf('В. Івасюк - Колиска вітру | Intro: Em G Em C Em'), <String>['Em', 'G', 'Em', 'C', 'Em']);
    expect(chordsOf('E - Am - E - Am - The bottle stands for lorn'), <String>['E', 'Am', 'E', 'Am']);
  });

  test('chords in brackets or parentheses anywhere', () {
    expect(chordsOf('[C] No one knows'), <String>['[C]']);
    expect(chordsOf('Because I (C) want a (G7) girl'), <String>['(C)', '(G7)']);
    expect(chordsOf('Drea-ea- [F] ea- [C] eam'), <String>['[F]', '[C]']);
  });

  test('words, sections and tabs are not chords', () {
    expect(chordsOf('A girl to hold in my arms'), isEmpty);
    expect(chordsOf('Am I wrong to love you'), isEmpty);
    expect(chordsOf('[Verse 1]\n[Bridge]\n(2 guitars)\n(x3)'), isEmpty);
    expect(chordsOf('e-----0---|\nB---1-----|'), isEmpty);
    expect(chordsOf('Біль у серці не стихне,'), isEmpty);
  });

  test('offsets point at the chord in the whole lyrics', () {
    const String lyrics = 'Intro\n  Am   G\nla la';
    final LyricsChord g = LyricsChord.findAll(lyrics).last;

    expect(lyrics.substring(g.start, g.end), 'G');
  });
}
