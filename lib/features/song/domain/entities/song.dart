import 'cover.dart';
import 'lyrics_chord.dart';
import 'lyrics_layout.dart';
import 'tab_block.dart';

/// Represents a song in the application.
///
/// Contains the core song metadata and a list of associated covers.
final class Song {
  /// The unique identifier for the song.
  final String id;

  /// The author/artist name for this song.
  final String author;

  /// The name/title of the song.
  final String name;

  /// The album name, if this song belongs to one.
  final String? album;

  /// The lyrics content for this song.
  final String lyrics;

  /// The list of covers associated with this song.
  final List<Cover> covers;

  /// Saved auto-scroll speed of the lyrics (0.0–1.0) on a phone, or `null` when never set.
  final double? scrollSpeed;

  /// Saved space above the lyrics before they scroll on a phone, as a part of the screen
  /// height (0.0–0.8), or `null` when never set.
  final double? leadIn;

  /// [scrollSpeed] on a big screen, or `null` when never set there.
  final double? wideScrollSpeed;

  /// [leadIn] on a big screen, or `null` when never set there.
  final double? wideLeadIn;

  /// Creates a new [Song] instance.
  const Song({
    required this.id,
    required this.author,
    required this.name,
    this.album,
    required this.lyrics,
    required this.covers,
    this.scrollSpeed,
    this.leadIn,
    this.wideScrollSpeed,
    this.wideLeadIn,
  });

  /// Every tablature in the [lyrics], in order; empty when the song has none.
  List<TabBlock> get tabs => TabBlock.findAll(lyrics);

  /// Every chord in the [lyrics] outside the tabs, in order; empty when the song has none.
  List<LyricsChord> get chords => LyricsChord.findAll(lyrics);

  /// The saved scroll speed on [layout]; a big screen takes the phone one until it has its own.
  double? scrollSpeedOn(LyricsLayout layout) => switch (layout) {
    LyricsLayout.compact => scrollSpeed,
    LyricsLayout.wide => wideScrollSpeed ?? scrollSpeed,
  };

  /// The saved space above the lyrics on [layout]; a big screen takes the phone one until it has
  /// its own.
  double? leadInOn(LyricsLayout layout) => switch (layout) {
    LyricsLayout.compact => leadIn,
    LyricsLayout.wide => wideLeadIn ?? leadIn,
  };
}
