/// Consecutive lines of the lyrics that hold a tablature (`e|--0--3--|`): they keep their columns only
/// in a fixed-width font and without wrapping.
///
/// [findAll] finds them. A tab line is a string of a guitar, a bass or a ukulele: an optional
/// string name and a bar (`e|`, `A|`, `G#|`, `D-`, `|`) followed by a body that is almost only
/// dashes, frets, bars and technique marks (`5h7p5`, `4\2`, `x`, `~`). Chord lines
/// (`| G Em | Am G ||`) and sung lines with hyphens (`Drea-ea-ea-ea-`) have letters or too few
/// dashes, so they stay text.
final class TabBlock {
  /// Fewest dashes in a tab line: a chord chart with `E - Am - E -` has fewer.
  static const int _minDashes = 6;

  /// Least share of tab characters in the body of a tab line.
  static const double _minTabShare = 0.9;

  /// Least share of dashes in the body of a tab line.
  static const double _minDashShare = 0.4;

  /// A count line under a tab: only beats (`1 2 3 4`, `1 & 2 +`) and spaces.
  static final RegExp _countLine = RegExp(r'^\s*[1-9](?:\s+[1-9&+])+\s*$');

  static const String _dash = '-';

  static const String _lineBreak = '\n';

  /// An optional string name with a bar, a colon or a dash, or a bare bar, at the start of a line.
  static final RegExp _stringPrefix = RegExp(r'^\s*(?:[A-Ga-g][#b]?\s*[|:\-]|\|)');

  /// Characters of a tab body: dashes, bars, frets, techniques, repeats, spaces.
  static final RegExp _tabCharacter = RegExp(r'[\-|0-9hpbrsxX/\\~()^.*=:<>\[\] ]');

  /// Offset of the first character of the first line in the lyrics.
  final int start;

  /// Offset just after the last character of the last line (its line break is not part of the block).
  final int end;

  /// Characters in the longest line of the block, trailing spaces left out.
  final int width;

  /// The lines of the tab as they are written in the lyrics.
  final String text;

  /// Creates a new [TabBlock].
  const TabBlock({required this.start, required this.end, required this.width, required this.text});

  /// The tab blocks of [lyrics] in order; empty when the lyrics have none.
  ///
  /// A count line (`1 2 3 4  1 2 3 4`) right above or under a tab belongs to it.
  static List<TabBlock> findAll(String lyrics) {
    final List<int> lineStarts = <int>[0];
    for (int index = lyrics.indexOf(_lineBreak); index >= 0; index = lyrics.indexOf(_lineBreak, index + 1)) {
      lineStarts.add(index + 1);
    }
    final List<String> lines = lyrics.split(_lineBreak);
    final List<bool> isTab = lines.map(isTabLine).toList();
    for (int index = 0; index < lines.length; index++) {
      if (isTab[index] || !_countLine.hasMatch(lines[index])) continue;
      final bool afterTab = index > 0 && isTab[index - 1];
      final bool beforeTab = index + 1 < lines.length && isTabLine(lines[index + 1]);
      if (afterTab || beforeTab) isTab[index] = true;
    }

    final List<TabBlock> blocks = <TabBlock>[];
    int index = 0;
    while (index < lines.length) {
      if (!isTab[index]) {
        index++;
        continue;
      }
      final int first = index;
      int width = 0;
      while (index < lines.length && isTab[index]) {
        final int lineWidth = lines[index].trimRight().length;
        if (lineWidth > width) width = lineWidth;
        index++;
      }
      final int start = lineStarts[first];
      final int end = lineStarts[index - 1] + lines[index - 1].length;
      blocks.add(TabBlock(start: start, end: end, width: width, text: lyrics.substring(start, end)));
    }
    return blocks;
  }

  /// Whether [line] is one string of a tablature.
  static bool isTabLine(String line) {
    final String trimmed = line.trim();
    if (trimmed.isEmpty) return false;
    final Match? prefix = _stringPrefix.firstMatch(trimmed);
    final String body = prefix == null ? trimmed : trimmed.substring(prefix.end);
    final int dashes = _dash.allMatches(body).length;
    if (dashes < _minDashes) return false;
    final int tabCharacters = _tabCharacter.allMatches(body).length;
    return tabCharacters / body.length >= _minTabShare && dashes / body.length >= _minDashShare;
  }

  @override
  bool operator ==(Object other) =>
      other is TabBlock && other.start == start && other.end == end && other.width == width && other.text == text;

  @override
  int get hashCode => Object.hash(start, end, width, text);
}
