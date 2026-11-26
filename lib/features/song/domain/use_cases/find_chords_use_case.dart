import '../entities/lyrics_chord.dart';

/// Finds the chords in lyrics being edited, so the page keeps them coloured.
///
/// The chords of a saved song are `Song.chords`; what counts as a chord is in [LyricsChord].
final class FindChordsUseCase {
  /// Creates a new [FindChordsUseCase] use case.
  const FindChordsUseCase();

  /// The chords of [lyrics] in order; empty when the lyrics have none.
  List<LyricsChord> call(String lyrics) => LyricsChord.findAll(lyrics);
}
