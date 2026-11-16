import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hitwave.cover/core/presentation/l10n/app_translations.dart';
import 'package:hitwave.cover/features/backup/domain/entities/import_choice.dart';
import 'package:hitwave.cover/features/backup/domain/entities/import_conflict.dart';
import 'package:hitwave.cover/features/backup/presentation/widgets/import_conflict_dialog_widget.dart';

void main() {
  const ImportConflict conflict = ImportConflict(
    index: 3,
    author: 'Дуже довгий виконавець з дуже довгим ім’ям',
    name: 'Дуже довга назва пісні, яка не влізе в один рядок',
    hasSameLyrics: false,
  );

  for (final Locale locale in const <Locale>[Locale('en'), Locale('isv')]) {
    testWidgets('fits a 320 px phone and answers for the others in ${locale.languageCode}', (
      WidgetTester tester,
    ) async {
      tester.view.physicalSize = const Size(320, 640);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      ImportConflictAnswer? answer;

      await tester.pumpWidget(
        MaterialApp(
          locale: locale,
          supportedLocales: const <Locale>[Locale('en'), Locale('isv')],
          localizationsDelegates: const <LocalizationsDelegate<Object>>[
            TranslationsDelegate(),
            GlobalMaterialLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            FallbackMaterialLocalizationsDelegate(),
            FallbackCupertinoLocalizationsDelegate(),
          ],
          home: Builder(
            builder: (BuildContext context) => Scaffold(
              body: Center(
                child: TextButton(
                  onPressed: () async => answer = await showDialog<ImportConflictAnswer>(
                    context: context,
                    builder: (BuildContext context) =>
                        const ImportConflictDialogWidget(conflict: conflict, othersCount: 5),
                  ),
                  child: const Text('open'),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);

      await tester.ensureVisible(find.byType(Checkbox));
      await tester.pumpAndSettle();
      await tester.tap(find.byType(Checkbox));
      await tester.pump();
      await tester.ensureVisible(find.byIcon(Icons.library_add_outlined));
      await tester.pumpAndSettle();
      await tester.tap(find.byIcon(Icons.library_add_outlined));
      await tester.pumpAndSettle();

      expect(answer?.choice, ImportChoice.keepBoth);
      expect(answer?.isForOthers, isTrue);
    });
  }
}
