import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hitwave.cover/features/song/domain/entities/cover.dart';
import 'package:hitwave.cover/features/song/domain/entities/song.dart';
import 'package:hitwave.cover/features/song/presentation/controllers/song_form_controller.dart';
import 'package:hitwave.cover/features/song/presentation/widgets/song_form_widget.dart';
import 'package:hitwave.cover/features/song/presentation/wrappers/song_form_wrapper.dart';
import 'package:hitwave.cover/core/presentation/l10n/app_translations.dart';

const SongFormTexts formTexts = SongFormTexts(
  artistLabel: 'Artist',
  songNameLabel: 'Song',
  albumLabel: 'Album',
  optionalText: 'optional',
  lyricsLabel: 'Lyrics',
  requiredText: 'Fill in this field',
);

void main() {
  late int submits;

  Future<SongFormController> pumpForm(WidgetTester tester, {Song? song}) async {
    final SongFormController songFormController = SongFormController(song: song);
    addTearDown(songFormController.dispose);
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: const <LocalizationsDelegate<Object>>[TranslationsDelegate()],
        home: Scaffold(
          body: SongFormWrapper(
            songFormController: songFormController,
            texts: formTexts,
            submitLabel: 'Save',
            onSubmitPressed: () => submits++,
          ),
        ),
      ),
    );
    return songFormController;
  }

  setUp(() => submits = 0);

  testWidgets('an empty form shows errors and may not be saved', (WidgetTester tester) async {
    final SongFormController songFormController = await pumpForm(tester);

    expect(songFormController.canSave(), isFalse);
    await tester.pump();

    expect(find.text('Fill in this field'), findsNWidgets(3));
  });

  testWidgets('a filled form may be saved with trimmed values and an empty album as null', (WidgetTester tester) async {
    final SongFormController songFormController = await pumpForm(tester);
    songFormController.authorController.text = ' Artist ';
    songFormController.nameController.text = 'Song';
    songFormController.albumController.text = '  ';
    songFormController.lyricsController.text = 'la la';

    expect(songFormController.canSave(), isTrue);
    expect(songFormController.author, 'Artist');
    expect(songFormController.album, isNull);
  });

  testWidgets('the save button calls onSubmit', (WidgetTester tester) async {
    await pumpForm(tester);

    await tester.tap(find.text('Save'));

    expect(submits, 1);
  });

  testWidgets('edit mode starts with the song values', (WidgetTester tester) async {
    const Song song = Song(id: '1', author: 'A', name: 'N', album: 'Al', lyrics: 'L', covers: <Cover>[]);
    final SongFormController songFormController = await pumpForm(tester, song: song);

    expect(songFormController.authorController.text, 'A');
    expect(songFormController.album, 'Al');
  });

  test('a new song added on the page of an artist starts with that artist', () {
    final SongFormController songFormController = SongFormController(author: 'Океан Ельзи');
    addTearDown(songFormController.dispose);

    expect(songFormController.author, 'Океан Ельзи');
    expect(songFormController.name, isEmpty);
  });
}
