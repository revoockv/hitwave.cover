import '../entities/lyrics_chord.dart';

/// Use case that finds a word the user said is not a chord, so it can become a chord again.
final class FindMarkedWordUseCase {
  /// Creates a new [FindMarkedWordUseCase].
  const FindMarkedWordUseCase();

  /// The marked word at [offset] of [lyrics], or `null`.
  ({int start, int end, String text})? call(String lyrics, int offset) => LyricsChord.markedWordAt(lyrics, offset);
}
