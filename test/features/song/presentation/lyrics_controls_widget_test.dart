import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hitwave.cover/features/song/presentation/controllers/lyrics_page_controller.dart';
import 'package:hitwave.cover/features/song/presentation/widgets/lyrics_controls_widget.dart';

void main() {
  for (final double width in <double>[320, 375, 560]) {
    testWidgets('the control panel fits a $width px wide screen while recording', (WidgetTester tester) async {
      tester.view.physicalSize = Size(width, 800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      final LyricsPageController lyricsPageController = LyricsPageController(lyrics: 'la la');
      addTearDown(lyricsPageController.dispose);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Align(
              alignment: Alignment.bottomCenter,
              child: LyricsControlsWidget(
                lyricsPageController: lyricsPageController,
                onSpeedChosen: (double _) {},
                onLeadInChosen: (double _) {},
                leadInLabel: 'Відступ',
                speedLabel: 'Швидкість',
                stopLabel: 'Пауза',
                startLabel: 'Старт',
                stopRecordingLabel: 'Зупинити запис',
                recordLabel: 'Запис',
                trimSilenceLabel: 'Обрізати тишу',
                onPlayPressed: () {},
                microphoneLabel: 'Мікрофон: Як у системі',
                onMicrophonePressed: () {},
                recordingElapsed: const Duration(minutes: 12, seconds: 34),
                recordingLevel: 0.5,
              ),
            ),
          ),
        ),
      );

      expect(tester.takeException(), isNull);
      expect(find.text('12:34'), findsOneWidget);
    });
  }
}
