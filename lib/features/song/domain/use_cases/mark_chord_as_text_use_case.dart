import '../entities/lyrics_chord.dart';

/// Use case that keeps a chord the app found as a plain word (`A girl`), when the user says it is not a chord.
final class MarkChordAsTextUseCase {
  /// Creates a new [MarkChordAsTextUseCase].
  const MarkChordAsTextUseCase();

  /// [lyrics] where [chord] stays text from now on.
  String call(String lyrics, LyricsChord chord) => LyricsChord.markAsText(lyrics, chord);
}
