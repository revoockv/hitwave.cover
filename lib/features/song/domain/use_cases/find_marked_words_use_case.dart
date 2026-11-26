import '../entities/lyrics_chord.dart';

/// Use case that finds the words the user said are not chords, so a tap can make them chords again.
final class FindMarkedWordsUseCase {
  /// Creates a new [FindMarkedWordsUseCase].
  const FindMarkedWordsUseCase();

  /// The marked words of [lyrics] in order.
  List<({int start, int end, String text})> call(String lyrics) => LyricsChord.markedWords(lyrics);
}
