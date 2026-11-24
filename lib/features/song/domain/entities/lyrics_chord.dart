import 'tab_block.dart';

/// A chord written in the lyrics (`Am`, `F#m7`, `D7/F#`, `[C]`, `(G7)`), so the page can colour it.
///
/// [findAll] finds them:
/// - on a line of chords only (`C#m   Am`, `| G Em | Am G ||`, `A(V) G(III) (2)`) every chord;
/// - on a line with words, a run of two or more chords (`C#m Am Коли ти смієшся`, `Intro: Em G Em`);
/// - anywhere, a chord in brackets or parentheses (`[Am]`, `Because I (C) want`).
///
/// A single plain word like `A` or `Am` among words stays text: in lyrics it is more often a word.
/// Tab lines ([TabBlock.isTabLine]) have no chords.
final class LyricsChord {
  /// A chord: root (`A`–`H`), accidental, quality, extensions, a position or an option in
  /// parentheses, a bass note, trailing marks (`G#m**`).
  static const String _chord =
      r'[A-H](?:#|b)?(?:maj|min|dim|aug|sus|add|m|M|°|ø|\+)*\d{0,2}(?:(?:maj|sus|add|b|#|\+|-)\d{1,2})*'
      r'(?:\([^)\s]*\))?(?:/[A-H](?:#|b)?)?\**';

  static final RegExp _plainChord = RegExp('^$_chord\$');
  static final RegExp _enclosedChord = RegExp('^(?:\\[$_chord\\]|\\($_chord\\))\$');

  /// Bars, repeats and fillers a chord line may hold besides chords.
  static final RegExp _neutral = RegExp(r'^(?:\|+:?|:?\|+|%|-+|=|\*+|x\d+|\(x?\d+\)|\d+x|/|\.+|,)$', caseSensitive: false);

  static final RegExp _token = RegExp(r'\S+');

  static const String _lineBreak = '\n';

  /// Fewest chords of a run on a line with words.
  static const int _minRun = 2;

  /// Offset of the first character of the chord in the lyrics (a bracket or parenthesis included).
  final int start;

  /// Offset just after its last character.
  final int end;

  /// The chord as written.
  final String text;

  /// Creates a new [LyricsChord].
  const LyricsChord({required this.start, required this.end, required this.text});

  /// The chords of [lyrics] in order; empty when the lyrics have none.
  static List<LyricsChord> findAll(String lyrics) {
    final List<LyricsChord> chords = <LyricsChord>[];
    int lineStart = 0;
    while (lineStart <= lyrics.length) {
      final int breakIndex = lyrics.indexOf(_lineBreak, lineStart);
      final int lineEnd = breakIndex < 0 ? lyrics.length : breakIndex;
      final String line = lyrics.substring(lineStart, lineEnd);
      if (!TabBlock.isTabLine(line)) {
        for (final Match token in _chordsOf(line)) {
          chords.add(LyricsChord(start: lineStart + token.start, end: lineStart + token.end, text: token[0]!));
        }
      }
      if (breakIndex < 0) break;
      lineStart = breakIndex + 1;
    }
    return chords;
  }

  /// The tokens of [line] that are chords.
  static List<Match> _chordsOf(String line) {
    final List<Match> tokens = _token.allMatches(line).toList();
    final List<_Kind> kinds = tokens.map((Match token) => _kindOf(token[0]!)).toList();
    final bool chordsOnly = !kinds.contains(_Kind.word) && kinds.any(_isChord);
    if (chordsOnly) {
      return <Match>[
        for (int i = 0; i < tokens.length; i++)
          if (_isChord(kinds[i])) tokens[i],
      ];
    }
    final List<Match> chords = <Match>[];
    final List<int> run = <int>[];
    void closeRun() {
      final int plain = run.where((int i) => kinds[i] == _Kind.plain).length;
      for (final int i in run) {
        if (kinds[i] == _Kind.enclosed || (kinds[i] == _Kind.plain && plain >= _minRun)) chords.add(tokens[i]);
      }
      run.clear();
    }

    for (int i = 0; i < tokens.length; i++) {
      if (kinds[i] == _Kind.word) {
        closeRun();
      } else {
        run.add(i);
      }
    }
    closeRun();
    return chords;
  }

  static _Kind _kindOf(String token) {
    if (_plainChord.hasMatch(token)) return _Kind.plain;
    if (_enclosedChord.hasMatch(token)) return _Kind.enclosed;
    if (_neutral.hasMatch(token)) return _Kind.neutral;
    return _Kind.word;
  }

  static bool _isChord(_Kind kind) => kind == _Kind.plain || kind == _Kind.enclosed;

  @override
  bool operator ==(Object other) =>
      other is LyricsChord && other.start == start && other.end == end && other.text == text;

  @override
  int get hashCode => Object.hash(start, end, text);
}

/// What a token of a lyrics line is.
enum _Kind {
  /// A chord as is (`Am`).
  plain,

  /// A chord in brackets or parentheses (`[Am]`, `(Am)`).
  enclosed,

  /// A bar, a repeat or a filler (`|`, `%`, `x2`).
  neutral,

  /// Anything else.
  word,
}
