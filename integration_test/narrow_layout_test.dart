// Every screen on a narrow phone (320 × 640), in both languages, with big numbers (long practice): no text may
// overflow. The screenshots are left for a look at the texts cut with "…" or touching each other:
//
//   flutter test integration_test/narrow_layout_test.dart -d macos \
//     --dart-define=HITWAVE_STORAGE_FOLDER=narrow_layout
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hitwave.cover/core/data/data_sources/local_storage_service.dart';
import 'package:hitwave.cover/core/presentation/l10n/strings.g.dart';
import 'package:hitwave.cover/features/settings/domain/entities/app_language.dart';
import 'package:hitwave.cover/features/settings/domain/entities/app_settings.dart';
import 'package:hitwave.cover/features/settings/presentation/di/settings_getters.dart';
import 'package:hitwave.cover/features/song/domain/entities/song_sort.dart';
import 'package:hitwave.cover/features/tuner/domain/entities/instrument.dart';
import 'package:hitwave.cover/features/tuner/presentation/l10n/tuner_texts.dart';
import 'package:hitwave.cover/main.dart' as app;
import 'package:integration_test/integration_test.dart';
import 'package:path_provider/path_provider.dart';

import 'demo_data.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('no text overflows on a narrow phone', (WidgetTester tester) async {
    expect(LocalStorageService.storageFolder, isNotEmpty, reason: 'run with --dart-define=HITWAVE_STORAGE_FOLDER=…');
    final Directory storage = Directory(
      '${(await getApplicationDocumentsDirectory()).path}/${LocalStorageService.storageFolder}',
    );
    if (storage.existsSync()) storage.deleteSync(recursive: true);
    final Directory out = Directory('${(await getTemporaryDirectory()).path}/hitwave_narrow_shots')
      ..createSync(recursive: true);

    // Every overflow is noted with the screen it was on, so one run finds them all.
    final List<String> overflows = <String>[];
    String screen = 'start';
    final FlutterExceptionHandler? report = FlutterError.onError;
    FlutterError.onError = (FlutterErrorDetails details) {
      final String text = details.exceptionAsString();
      if (text.contains('overflowed')) {
        overflows.add('$screen: ${text.split('\n').first}');
      } else {
        report?.call(details);
      }
    };

    Future<void> settle() async {
      for (int i = 0; i < 24; i++) {
        await tester.pump(const Duration(milliseconds: 50));
      }
    }

    Future<void> shot(String name) async {
      screen = name;
      await settle();
      final RenderView view = tester.binding.renderViews.first;
      final OffsetLayer layer = view.debugLayer! as OffsetLayer;
      final ByteData? png = await tester.runAsync<ByteData?>(() async {
        final ui.Image image = await layer.toImage(Offset.zero & tester.view.physicalSize);
        return image.toByteData(format: ui.ImageByteFormat.png);
      });
      File('${out.path}/$name.png').writeAsBytesSync(png!.buffer.asUint8List());
    }

    Finder tab(IconData icon) => find.descendant(
      of: find.byWidgetPredicate((Widget w) => w is NavigationBar || w is NavigationRail),
      matching: find.byIcon(icon),
    );

    Future<void> tapIfThere(Finder finder) async {
      if (finder.evaluate().isEmpty) return;
      await tester.tap(finder.first, warnIfMissed: false);
      await settle();
    }

    Future<void> back() async {
      await tester.pageBack();
      await settle();
    }

    // Long practice: about five hours a day, so the week, the month and the total have hours of two digits.
    await app.main();
    await settle();
    await seedDemoData(storage: storage, settings: AppSettings.initial, sessionSeconds: 5 * 3600);
    await tester.pumpWidget(const SizedBox());
    await app.main();
    await settle();

    tester.view.devicePixelRatio = 2;
    tester.view.physicalSize = const Size(320 * 2, 640 * 2);
    await settle();

    for (final (AppLanguage language, AppLocale locale) in <(AppLanguage, AppLocale)>[
      (AppLanguage.english, AppLocale.en),
      (AppLanguage.interslavic, AppLocale.isv),
    ]) {
      await setLanguageUseCase(language);
      await settle();
      final Translations t = locale.buildSync();
      final String l = locale.languageCode;

      await tapIfThere(tab(Icons.home_outlined));
      await shot('${l}_home');

      await tapIfThere(tab(Icons.queue_music_outlined));
      for (final SongSort sort in SongSort.values) {
        await tapIfThere(
          find.widgetWithText(ChoiceChip, switch (sort) {
            SongSort.artists => t.song.sort.artists,
            SongSort.name => t.song.sort.name,
            SongSort.recent => t.song.sort.recent,
            SongSort.covers => t.song.sort.covers,
          }),
        );
        await shot('${l}_songs_${sort.name}');
      }
      await tapIfThere(find.text('Northern Lights'));
      await shot('${l}_artist');
      await tapIfThere(find.byTooltip(t.song.actions));
      await shot('${l}_song_menu');
      await tapIfThere(find.text(t.song.edit));
      await shot('${l}_song_form');
      await back();

      await tapIfThere(find.text('Paper Boats'));
      await shot('${l}_lyrics');
      await tapIfThere(find.byIcon(Icons.library_music_outlined));
      await shot('${l}_takes');
      await tester.tapAt(const Offset(160, 40));
      await settle();
      await back();

      await tapIfThere(tab(Icons.mic_none_outlined));
      await shot('${l}_covers');
      await tapIfThere(tab(Icons.insights_outlined));
      await shot('${l}_stats');
      await tester.drag(find.byType(Scrollable).first, const Offset(0, -500));
      await shot('${l}_stats_end');

      await tapIfThere(tab(Icons.graphic_eq_outlined));
      for (final Instrument instrument in Instrument.values) {
        await tapIfThere(find.widgetWithText(ChoiceChip, t.instrumentLabel(instrument)));
        await shot('${l}_tuner_${instrument.name}');
      }

      await tapIfThere(find.byIcon(Icons.settings_outlined));
      await shot('${l}_settings');
      await tester.drag(find.byType(Scrollable).first, const Offset(0, -900));
      await shot('${l}_settings_end');
      await tapIfThere(find.text(t.settings.clearData));
      await shot('${l}_clear_data');
      await tapIfThere(find.text(t.common.cancel));
      await tapIfThere(find.text(t.song.sync));
      await shot('${l}_sync');
      await back();
      await back();
    }

    await setLanguageUseCase(AppLanguage.english);
    storage.deleteSync(recursive: true);
    FlutterError.onError = report;
    // ignore: avoid_print
    print('SHOTS ${out.path}');
    // ignore: avoid_print
    print('OVERFLOWS ${overflows.length}\n${overflows.toSet().join('\n')}');
    expect(overflows, isEmpty);
  });
}
