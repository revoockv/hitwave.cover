import '../entities/lyrics_chord.dart';

/// Use case that lets a word the user marked as text be found as a chord again.
final class UnmarkChordUseCase {
  /// Creates a new [UnmarkChordUseCase].
  const UnmarkChordUseCase();

  /// [lyrics] without the mark of the word between [start] and [end].
  String call(String lyrics, int start, int end) => LyricsChord.unmark(lyrics, start, end);
}
