import 'package:flutter_test/flutter_test.dart';
import 'package:hitwave.cover/features/song/domain/entities/song.dart';
import 'package:hitwave.cover/features/song/domain/entities/tab_block.dart';
import 'package:hitwave.cover/features/song/domain/use_cases/find_tab_blocks_use_case.dart';

void main() {
  const FindTabBlocksUseCase findTabBlocks = FindTabBlocksUseCase();

  group('TabBlock.isTabLine', () {
    test('guitar strings with names, bars and techniques are tab lines', () {
      for (final String line in <String>[
        'e----------------------------|',
        'B-5h7p5---4-5----------------|',
        'A|0-------------0-|4-4\\2-----------|0-------------0-|4-4\\2-2---------|',
        'A|--5-55---7-5-3-2-22----0-3-2-2---0-3---2-222-22-]',
        "C|------|2---------------|------2-------2-|----------------|------2-------2-| ",
        '|-3--2--0-----------|-3---||-0--------3--0-----|-0---||',
        'G#|---3---',
      ]) {
        expect(TabBlock.isTabLine(line), isTrue, reason: line);
      }
    });

    test('chords, chord charts and sung lines are not tab lines', () {
      for (final String line in <String>[
        '       E             Am           E',
        'Here inside, where I hide with my loneliness',
        '| G Em |',
        'F | F Eb Bb || F | F Eb C ||',
        '|: G | G | G | D7 | G | F | C |',
        'E - Am - E - Am - Am - Am - Am - The company was gay, we turned night into day',
        '(fading) [C] Drea-ea-ea-ea-[Am]eam',
        'My little runaway, my run-run-run-run- runaway',
        'Am F F F G Am Girl---, help me, I... I can\'t think of nothing but you,',
        '                                                     let ring-| (2 guitars)',
        '',
        '   ',
      ]) {
        expect(TabBlock.isTabLine(line), isFalse, reason: line);
      }
    });
  });

  group('FindTabBlocksUseCase', () {
    test('finds nothing in lyrics with chords only', () {
      expect(
        findTabBlocks('E\n \nE               G#m\nPlease lock me away\n    C#m\nAnd don\'t allow the day'),
        isEmpty,
      );
    });

    test('joins consecutive tab lines into one block without the line break after it', () {
      const String intro = 'Intro:\n';
      const String tab = 'e-----0---|\nB---1-----|\nG-0-------|';
      const String lyrics = '$intro$tab\nHello\n';

      final List<TabBlock> blocks = findTabBlocks(lyrics);

      expect(blocks, <TabBlock>[
        const TabBlock(start: intro.length, end: intro.length + tab.length, width: 11, text: tab),
      ]);
      expect(lyrics.substring(blocks.single.start, blocks.single.end), tab);
    });

    test('splits blocks at any other line and finds a block at the very end', () {
      const String lyrics = 'A|----2-0---|\nE|--2-----2-|\n\nA|0-------0-|';

      final List<TabBlock> blocks = findTabBlocks(lyrics);

      expect(blocks, hasLength(2));
      expect(lyrics.substring(blocks.last.start, blocks.last.end), 'A|0-------0-|');
    });

    test('a count line next to a tab belongs to it, a number line elsewhere does not', () {
      const String tab = 'A|--2-0---|\nE|2-----2-|\n  1 2 3 4';
      final List<TabBlock> blocks = findTabBlocks('$tab\n\n1 2 3 4\nLa la');

      expect(blocks.single.text, tab);
    });

    test('the width is the longest line without trailing spaces', () {
      final List<TabBlock> blocks = findTabBlocks('e-------|   \nB-----------|');

      expect(blocks.single.width, 13);
    });
  });

  test('Song.tabs gives the text of every tab of the song', () {
    const Song song = Song(
      id: 's1',
      author: 'The Beatles',
      name: 'That Means A Lot',
      lyrics: 'Intro\ne-----0---|\nB---1-----|\nLa la\nA|--2--|---0--|',
      covers: <Never>[],
    );

    expect(song.tabs.map((TabBlock tab) => tab.text), <String>['e-----0---|\nB---1-----|', 'A|--2--|---0--|']);
  });
}
