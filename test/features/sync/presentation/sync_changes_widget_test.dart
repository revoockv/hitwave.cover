import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hitwave.cover/core/presentation/l10n/app_translations.dart';
import 'package:hitwave.cover/features/sync/domain/entities/song_difference.dart';
import 'package:hitwave.cover/features/sync/domain/entities/sync_change.dart';
import 'package:hitwave.cover/features/sync/presentation/l10n/sync_texts.dart';
import 'package:hitwave.cover/features/sync/presentation/widgets/sync_changes_widget.dart';

void main() {
  final List<SyncChange> changes = <SyncChange>[
    const SyncChange(
      id: 'a',
      kind: SyncChangeKind.add,
      direction: SyncDirection.toHere,
      subject: SyncSubject.song,
      songTitle: 'Дуже довга назва пісні, яка не влізе — Дуже довгий виконавець',
      count: 3,
    ),
    SyncChange(
      id: 'd',
      kind: SyncChangeKind.delete,
      direction: SyncDirection.toHere,
      subject: SyncSubject.cover,
      songTitle: 'Обійми — Океан Ельзи',
      coverRecordedAt: DateTime(2026, 11, 12, 9),
      deletedAt: DateTime(2026, 11, 14, 20, 5),
    ),
    const SyncChange(
      id: 'u',
      kind: SyncChangeKind.update,
      direction: SyncDirection.toThere,
      subject: SyncSubject.song,
      songTitle: 'Stefania — Kalush',
      differences: <SongDifference>{SongDifference.lyrics, SongDifference.album},
      chosenFirst: false,
    ),
    const SyncChange(
      id: 'p',
      kind: SyncChangeKind.add,
      direction: SyncDirection.toThere,
      subject: SyncSubject.practice,
      count: 4,
    ),
  ];

  for (final Locale locale in const <Locale>[Locale('en'), Locale('isv')]) {
    testWidgets('the changes fit a 320 px wide phone in ${locale.languageCode}', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(320, 1400);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      final List<(String, bool)> ticked = <(String, bool)>[];

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
          home: Scaffold(
            body: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Builder(
                builder: (BuildContext context) => SyncChangesWidget(
                  changes: changes,
                  chosen: const <String>{'a', 'd', 'p'},
                  texts: context.t.syncChanges('Galaxy A07'),
                  onChosenChanged: (SyncChange change, bool isChosen) => ticked.add((change.id, isChosen)),
                  onAllChosenChanged: (List<SyncChange> _, bool _) {},
                  onApplyPressed: () {},
                  onCancelPressed: () {},
                ),
              ),
            ),
          ),
        ),
      );

      expect(tester.takeException(), isNull);
      expect(find.textContaining('Galaxy A07'), findsWidgets);
      await tester.tap(find.textContaining('Stefania'));
      expect(ticked, <(String, bool)>[('u', true)]);
    });
  }
}
