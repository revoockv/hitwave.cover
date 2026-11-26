import 'tab_block.dart';

/// A chord written in the lyrics (`Am`, `F#m7`, `D7/F#`, `[C]`, `(G7)`), so the page can colour it.
///
/// [findAll] finds them:
/// - on a line of chords only (`C#m   Am`, `| G Em | Am G ||`, `A(V) G(III) (2)`) every chord;
/// - on a line with words, a run of two or more chords (`C#m Am Коли ти смієшся`, `Intro: Em G Em`);
/// - anywhere, a chord in brackets or parentheses (`[Am]`, `Because I (C) want`), and every chord of brackets that
///   hold chords only (`[F Dm] Duke, Duke`, `(Am | G)`);
/// - a chord in square brackets even inside a word, as ChordPro writes it (`[Am]We folded every [F]promise`);
/// - in a song with chords (chords on at least two lines by the rules above), also a lone chord among words
///   (`Bb Duke, Duke of Earl`, `C 'Cause I'm the Duke`).
///
/// Elsewhere a single plain word like `A` or `Am` among words stays text: in lyrics it is more often a word. Even in a
/// song with chords `A` and `Am` before a Latin word (`A girl to hold`, `Am I wrong`) stay text.
/// Tab lines ([TabBlock.isTabLine]) have no chords.
///
/// A chord the user said is a word ([markAsText]) has an invisible [textMark] before it and stays text; the mark
/// goes with the lyrics everywhere (sync, backup), and [unmark] takes it away.
final class LyricsChord {
  /// A chord: root (`A`–`H`), accidental, quality, extensions, a position or an option in
  /// parentheses, a bass note, trailing marks (`G#m**`).
  static const String _chord =
      r'[A-H](?:#|b)?(?:maj|min|dim|aug|sus|add|m|M|°|ø|\+)*\d{0,2}(?:(?:maj|sus|add|dim|aug)\d{0,2}|(?:b|#|\+|-)\d{1,2})*'
      r'(?:\([^)\s]*\))?(?:/[A-H](?:#|b)?)?\**';

  static final RegExp _plainChord = RegExp('^$_chord\$');
  static final RegExp _enclosedChord = RegExp('^(?:\\[$_chord\\]|\\($_chord\\))\$');

  /// A chord in square brackets anywhere in a line, also glued to a word (`[Am]We`).
  static final RegExp _inlineChord = RegExp('\\[$_chord\\]');

  /// Put before a chord the user said is a word, so it stays text (U+2060 WORD JOINER: invisible, no space).
  static const String textMark = '\u2060';

  /// Bars, repeats and fillers a chord line may hold besides chords.
  static final RegExp _neutral = RegExp(
    r'^(?:\|+:?|:?\|+|%|-+|=|\*+|x\d+|\(x?\d+\)|\d+x|/|\.+|,)$',
    caseSensitive: false,
  );

  static final RegExp _token = RegExp(r'\S+');

  /// Brackets or parentheses around several tokens (`[F Dm]`), that may be a group of chords.
  static final RegExp _group = RegExp(r'[\[(]([^\[\]()]*\s[^\[\]()]*)[\])]');

  /// The lone chords that are words more often, kept as text before a Latin word.
  static const Set<String> _wordLike = <String>{'A', 'Am'};

  /// A word that starts with a Latin letter.
  static final RegExp _latinWord = RegExp(r'^[^A-Za-z\u0400-\u04FF]*[A-Za-z]');

  /// Fewest lines with chords that make the lyrics a song with chords.
  static const int _minChordLines = 2;

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
    final List<_Line> lines = <_Line>[];
    int lineStart = 0;
    while (lineStart <= lyrics.length) {
      final int breakIndex = lyrics.indexOf(_lineBreak, lineStart);
      final int lineEnd = breakIndex < 0 ? lyrics.length : breakIndex;
      final String line = lyrics.substring(lineStart, lineEnd);
      if (!TabBlock.isTabLine(line)) lines.add(_chordsOf(line, lineStart));
      if (breakIndex < 0) break;
      lineStart = breakIndex + 1;
    }
    final bool withChords = lines.where((_Line line) => line.chords.isNotEmpty).length >= _minChordLines;
    return <LyricsChord>[
      for (final _Line line in lines)
        ...(withChords ? (<LyricsChord>[...line.chords, ...line.lone]..sort(_byStart)) : line.chords),
    ];
  }

  static int _byStart(LyricsChord a, LyricsChord b) => a.start.compareTo(b.start);

  /// The chords of [line] that starts at [offset] in the lyrics, and its lone chords among words.
  static _Line _chordsOf(String line, int offset) {
    final List<Match> tokens = _token.allMatches(_ungrouped(line)).toList();
    final List<_Kind> kinds = tokens.map((Match token) => _kindOf(token[0]!)).toList();
    _markGroups(line, tokens, kinds);
    LyricsChord chordAt(int i) =>
        LyricsChord(start: offset + tokens[i].start, end: offset + tokens[i].end, text: tokens[i][0]!);

    final bool chordsOnly = !kinds.contains(_Kind.word) && kinds.any(_isChord);
    if (chordsOnly) {
      return _Line(
        chords: <LyricsChord>[
          for (int i = 0; i < tokens.length; i++)
            if (_isChord(kinds[i])) chordAt(i),
        ],
        lone: const <LyricsChord>[],
      );
    }
    final List<LyricsChord> chords = <LyricsChord>[];
    final List<LyricsChord> lone = <LyricsChord>[];
    final List<int> run = <int>[];
    void closeRun(int next) {
      final List<int> plain = run.where((int i) => kinds[i] == _Kind.plain).toList();
      for (final int i in run) {
        if (kinds[i] == _Kind.enclosed || (kinds[i] == _Kind.plain && plain.length >= _minRun)) chords.add(chordAt(i));
      }
      if (plain.length == 1 && !_isWord(tokens[plain.single][0]!, next < tokens.length ? tokens[next][0]! : null)) {
        lone.add(chordAt(plain.single));
      }
      run.clear();
    }

    for (int i = 0; i < tokens.length; i++) {
      if (kinds[i] == _Kind.word) {
        closeRun(i);
      } else {
        run.add(i);
      }
    }
    closeRun(tokens.length);
    for (final Match inline in _inlineChord.allMatches(line)) {
      final int start = offset + inline.start;
      if (chords.any((LyricsChord chord) => chord.start <= start && start < chord.end)) continue;
      chords.add(LyricsChord(start: start, end: offset + inline.end, text: inline[0]!));
    }
    chords.sort(_byStart);
    return _Line(chords: chords, lone: lone);
  }

  /// [line] with the brackets of its chord groups ([_group]) turned into spaces, so their chords are tokens of their
  /// own at the same offsets.
  static String _ungrouped(String line) => line.replaceAllMapped(_group, (Match group) {
    final String inside = group[1]!;
    return _isChordGroup(inside) ? ' $inside ' : group[0]!;
  });

  /// Marks the chords inside the chord groups of [line] as always chords, like a chord in brackets.
  static void _markGroups(String line, List<Match> tokens, List<_Kind> kinds) {
    for (final Match group in _group.allMatches(line)) {
      if (!_isChordGroup(group[1]!)) continue;
      for (int i = 0; i < tokens.length; i++) {
        if (tokens[i].start > group.start && tokens[i].end < group.end && kinds[i] == _Kind.plain) {
          kinds[i] = _Kind.enclosed;
        }
      }
    }
  }

  /// Whether the tokens of [inside] are chords, bars and repeats only, with at least one chord.
  static bool _isChordGroup(String inside) {
    final List<_Kind> kinds = _token.allMatches(inside).map((Match token) => _kindOf(token[0]!)).toList();
    return kinds.contains(_Kind.plain) && kinds.every((_Kind kind) => kind == _Kind.plain || kind == _Kind.neutral);
  }

  /// Whether a lone [chord] before [next] is more likely a word (`A girl`, `Am I wrong`).
  static bool _isWord(String chord, String? next) =>
      _wordLike.contains(chord) && next != null && _latinWord.hasMatch(next);

  static _Kind _kindOf(String token) {
    if (_plainChord.hasMatch(token)) return _Kind.plain;
    if (_enclosedChord.hasMatch(token)) return _Kind.enclosed;
    if (_neutral.hasMatch(token)) return _Kind.neutral;
    return _Kind.word;
  }

  static bool _isChord(_Kind kind) => kind == _Kind.plain || kind == _Kind.enclosed;

  /// [lyrics] with [chord] marked as a word: [textMark] before its first letter (inside its bracket).
  static String markAsText(String lyrics, LyricsChord chord) {
    final int at = chord.start + (chord.text.startsWith('[') || chord.text.startsWith('(') ? 1 : 0);
    return lyrics.replaceRange(at, at, textMark);
  }

  /// The words of [lyrics] that were chords the user marked as words, in order: their ranges and their texts without
  /// the mark.
  static List<({int start, int end, String text})> markedWords(String lyrics) => <({int start, int end, String text})>[
    for (final Match word in _token.allMatches(lyrics))
      if (word[0]!.contains(textMark)) (start: word.start, end: word.end, text: word[0]!.replaceAll(textMark, '')),
  ];

  /// [lyrics] without the [textMark]s between [start] and [end]: the word there may be a chord again.
  static String unmark(String lyrics, int start, int end) =>
      lyrics.replaceRange(start, end, lyrics.substring(start, end).replaceAll(textMark, ''));

  @override
  bool operator ==(Object other) =>
      other is LyricsChord && other.start == start && other.end == end && other.text == text;

  @override
  int get hashCode => Object.hash(start, end, text);
}

/// The chords found on one line of lyrics.
final class _Line {
  /// Chords by the rules of a line alone.
  final List<LyricsChord> chords;

  /// Lone plain chords among words, chords only in a song with chords.
  final List<LyricsChord> lone;

  /// Creates a new [_Line].
  const _Line({required this.chords, required this.lone});
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
