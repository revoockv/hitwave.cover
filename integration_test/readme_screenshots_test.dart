// Screenshots for the README, made from demo songs in a storage folder of their own:
//
//   flutter test integration_test/readme_screenshots_test.dart -d macos \
//     --dart-define=HITWAVE_STORAGE_FOLDER=readme_screenshots
//
// The PNGs are written to `<temp>/hitwave_readme_shots` (the path is printed) and copied to docs/screenshots/.
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hitwave.cover/core/data/data_sources/local_storage_service.dart';
import 'package:hitwave.cover/features/history/presentation/di/history_getters.dart';
import 'package:hitwave.cover/features/settings/domain/entities/accent_color.dart';
import 'package:hitwave.cover/features/settings/domain/entities/app_settings.dart';
import 'package:hitwave.cover/features/settings/domain/entities/app_theme_style.dart';
import 'package:hitwave.cover/features/settings/presentation/di/settings_getters.dart';
import 'package:hitwave.cover/features/song/domain/entities/lyrics_layout.dart';
import 'package:hitwave.cover/features/song/domain/entities/song.dart';
import 'package:hitwave.cover/features/song/presentation/di/song_getters.dart';
import 'package:hitwave.cover/main.dart' as app;
import 'demo_data.dart';
import 'package:integration_test/integration_test.dart';
import 'package:path_provider/path_provider.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('README screenshots', (WidgetTester tester) async {
    expect(LocalStorageService.storageFolder, isNotEmpty, reason: 'run with --dart-define=HITWAVE_STORAGE_FOLDER=…');
    final Directory storage = Directory(
      '${(await getApplicationDocumentsDirectory()).path}/${LocalStorageService.storageFolder}',
    );
    if (storage.existsSync()) storage.deleteSync(recursive: true);
    final Directory out = Directory('${(await getTemporaryDirectory()).path}/hitwave_readme_shots')
      ..createSync(recursive: true);

    Finder tab(IconData icon) => find.descendant(
      of: find.byWidgetPredicate((Widget w) => w is NavigationBar || w is NavigationRail),
      matching: find.byIcon(icon),
    );

    Future<void> settle() async {
      for (int i = 0; i < 30; i++) {
        await tester.pump(const Duration(milliseconds: 50));
      }
    }

    Future<void> shot(String name) async {
      await settle();
      final RenderView view = tester.binding.renderViews.first;
      final OffsetLayer layer = view.debugLayer! as OffsetLayer;
      final ByteData? png = await tester.runAsync<ByteData?>(() async {
        final ui.Image image = await layer.toImage(Offset.zero & tester.view.physicalSize);
        return image.toByteData(format: ui.ImageByteFormat.png);
      });
      File('${out.path}/$name.png').writeAsBytesSync(png!.buffer.asUint8List());
    }

    // 1. Demo songs, then two weeks of practice on them; the app starts again to read the practice.
    await app.main();
    await settle();
    final List<Song> songs = await seedDemoData(
      storage: storage,
      settings: AppSettings.initial.copyWith(themeStyle: AppThemeStyle.glassDark),
    );
    // The root widget of the first start still watches the old settings, so it goes before the app starts again.
    await tester.pumpWidget(const SizedBox());
    await app.main();
    await settle();
    for (int i = 2; i >= 0; i--) {
      await markCoverPlayedUseCase('demo-take-$i');
    }
    final String paperBoats = songs.firstWhere((Song song) => song.name == 'Paper Boats').id;
    for (final LyricsLayout layout in LyricsLayout.values) {
      await updateSongLeadInUseCase(songId: paperBoats, layout: layout, leadIn: 0.05);
    }

    // 2. Phone screens.
    tester.view.devicePixelRatio = 2;
    tester.view.physicalSize = const Size(400 * 2, 860 * 2);
    await settle();
    await tester.tap(tab(Icons.queue_music_outlined));
    await settle();
    await tester.tap(find.text('A–Z').first);
    await shot('phone_songs');
    await tester.tap(find.text('Paper Boats').first);
    await shot('phone_lyrics');
    await tester.pageBack();
    await settle();
    await tester.tap(tab(Icons.home_outlined));
    await shot('phone_home');
    await tester.tap(tab(Icons.mic_none_outlined));
    await shot('phone_covers');
    await tester.tap(tab(Icons.insights_outlined));
    await shot('phone_stats');
    // The tuner listens to the microphone; without a sound it waits for a string.
    await tester.tap(tab(Icons.graphic_eq_outlined));
    await shot('phone_tuner');
    await tester.tap(find.byIcon(Icons.settings_outlined).first);
    await shot('phone_settings');
    await tester.pageBack();
    await settle();

    // 3. A wide window.
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(1440, 900);
    await settle();
    await tester.tap(tab(Icons.home_outlined));
    await shot('wide_home');
    await tester.tap(tab(Icons.queue_music_outlined));
    await settle();
    await tester.tap(find.text('Paper Boats').first);
    await shot('wide_lyrics');
    await tester.pageBack();
    await settle();

    // 4. The looks: every theme style with another accent, on the home tab of a phone.
    tester.view.devicePixelRatio = 2;
    tester.view.physicalSize = const Size(400 * 2, 860 * 2);
    await tester.tap(tab(Icons.home_outlined));
    const List<(AppThemeStyle, AccentColor)> looks = <(AppThemeStyle, AccentColor)>[
      (AppThemeStyle.glassLight, AccentColor.raspberry),
      (AppThemeStyle.glassDark, AccentColor.gold),
      (AppThemeStyle.neumorphicLight, AccentColor.azure),
      (AppThemeStyle.neumorphicDark, AccentColor.olive),
    ];
    for (final (AppThemeStyle style, AccentColor accent) in looks) {
      await setThemeStyleUseCase(style);
      await setAccentColorUseCase(accent);
      await shot('look_${style.name}');
    }

    storage.deleteSync(recursive: true);
    // ignore: avoid_print
    print('SHOTS ${out.path}');
  });
}
