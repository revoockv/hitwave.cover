import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hitwave.cover/core/domain/entities/result.dart';
import 'package:hitwave.cover/features/song/domain/entities/cover.dart';
import 'package:hitwave.cover/features/song/domain/entities/song.dart';
import 'package:hitwave.cover/features/song/presentation/controllers/song_form_controller.dart';
import 'package:hitwave.cover/features/song/presentation/widgets/song_form_widget.dart';

void main() {
  late List<String> saved;

  Future<Result<void>> save({required String author, required String name, String? album, required String lyrics}) async {
    saved.add('$author|$name|$album|$lyrics');
    return Result.ok;
  }

  Future<SongFormController> pumpForm(WidgetTester tester, {Song? song}) async {
    final SongFormController controller = SongFormController(save: save, song: song);
    addTearDown(controller.dispose);
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: SongFormWidget(controller: controller, submitLabel: 'Save')),
      ),
    );
    return controller;
  }

  setUp(() => saved = <String>[]);

  testWidgets('an empty form shows errors and does not save', (WidgetTester tester) async {
    final SongFormController controller = await pumpForm(tester);

    await controller.save();
    await tester.pump();

    expect(saved, isEmpty);
    expect(find.text('Заповніть це поле'), findsNWidgets(3));
  });

  testWidgets('a filled form saves trimmed values and an empty album as null', (WidgetTester tester) async {
    final SongFormController controller = await pumpForm(tester);
    controller.author.text = ' Artist ';
    controller.name.text = 'Song';
    controller.album.text = '  ';
    controller.lyrics.text = 'la la';

    await controller.save();

    expect(saved, <String>['Artist|Song|null|la la']);
    expect(controller.value.isSuccess, isTrue);
  });

  testWidgets('edit mode starts with the song values', (WidgetTester tester) async {
    const Song song = Song(id: '1', author: 'A', name: 'N', album: 'Al', lyrics: 'L', covers: <Cover>[]);
    final SongFormController controller = await pumpForm(tester, song: song);

    expect(controller.author.text, 'A');
    expect(controller.album.text, 'Al');
  });
}
