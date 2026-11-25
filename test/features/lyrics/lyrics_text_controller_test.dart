import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hitwave.cover/features/song/domain/entities/lyrics_chord.dart';
import 'package:hitwave.cover/features/song/domain/entities/tab_block.dart';
import 'package:hitwave.cover/features/song/domain/use_cases/find_tab_blocks_use_case.dart';
import 'package:hitwave.cover/features/lyrics/presentation/controllers/lyrics_text_controller.dart';

void main() {
  const String lyrics = 'Intro\ne-----0---|\nB---1-----|\nLa la';
  const TextStyle lyricsStyle = TextStyle(fontSize: 20);

  /// The spans the field would draw for [lyricsTextController].
  Future<TextSpan> spansOf(WidgetTester tester, LyricsTextController lyricsTextController) async {
    late TextSpan span;
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (BuildContext context) {
            span = lyricsTextController.buildTextSpan(context: context, style: lyricsStyle, withComposing: false);
            return const SizedBox();
          },
        ),
      ),
    );
    return span;
  }

  testWidgets('without tabs the text is one plain span', (WidgetTester tester) async {
    final LyricsTextController lyricsTextController = LyricsTextController(text: 'La la');
    addTearDown(lyricsTextController.dispose);

    final TextSpan span = await spansOf(tester, lyricsTextController);

    expect(span.text, 'La la');
    expect(span.children, isNull);
  });

  testWidgets('a tab is drawn in a fixed-width font between the plain parts', (WidgetTester tester) async {
    final LyricsTextController lyricsTextController = LyricsTextController(
      text: lyrics,
      tabBlocks: const FindTabBlocksUseCase()(lyrics),
    );
    addTearDown(lyricsTextController.dispose);

    final TextSpan span = await spansOf(tester, lyricsTextController);
    final List<TextSpan> children = span.children!.cast<TextSpan>();

    expect(children.map((TextSpan child) => child.text), <String>['Intro\n', 'e-----0---|\nB---1-----|', '\nLa la']);
    expect(children[1].style?.fontFamily, 'RobotoMono');
    expect(children[1].style?.fontSize, 20);
    expect(children.first.style, isNull);
  });

  testWidgets('a tab wider than the field gets a smaller font, but not below the least', (WidgetTester tester) async {
    final LyricsTextController narrowController = LyricsTextController(
      text: lyrics,
      tabBlocks: const FindTabBlocksUseCase()(lyrics),
    )..lineWidth = 80;
    final LyricsTextController tinyController = LyricsTextController(
      text: lyrics,
      tabBlocks: const FindTabBlocksUseCase()(lyrics),
    )..lineWidth = 10;
    addTearDown(narrowController.dispose);
    addTearDown(tinyController.dispose);

    final double narrowSize = (await spansOf(tester, narrowController)).children![1].style!.fontSize!;
    final double tinySize = (await spansOf(tester, tinyController)).children![1].style!.fontSize!;

    expect(narrowSize, lessThan(20));
    expect(tinySize, 7);
  });

  testWidgets('blocks past the end of an edited text are not used', (WidgetTester tester) async {
    final LyricsTextController lyricsTextController = LyricsTextController(
      text: 'e-----0---|',
      tabBlocks: const <TabBlock>[TabBlock(start: 0, end: 40, width: 40, text: '')],
    );
    addTearDown(lyricsTextController.dispose);

    final TextSpan span = await spansOf(tester, lyricsTextController);

    expect(span.children, isNull);
  });

  testWidgets('chords take the accent colour, the words between them stay plain', (WidgetTester tester) async {
    const String song = 'Am   G\nla la\ne-----0---|\nB---1-----|';
    final LyricsTextController lyricsTextController = LyricsTextController(
      text: song,
      tabBlocks: const FindTabBlocksUseCase()(song),
      chords: LyricsChord.findAll(song),
    );
    addTearDown(lyricsTextController.dispose);

    final List<TextSpan> children = (await spansOf(tester, lyricsTextController)).children!.cast<TextSpan>();

    expect(children.map((TextSpan child) => child.text), <String>[
      'Am',
      '   ',
      'G',
      '\nla la\n',
      'e-----0---|\nB---1-----|',
    ]);
    expect(children.first.style?.color, ThemeData().colorScheme.primary);
    expect(children[1].style, isNull);
    expect(children.last.style?.fontFamily, 'RobotoMono');
  });
}
