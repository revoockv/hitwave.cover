import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hitwave.cover/core/domain/entities/result.dart';
import 'package:hitwave.cover/core/presentation/l10n/app_translations.dart';
import 'package:hitwave.cover/features/tuner/domain/entities/tuner_failure.dart';
import 'package:hitwave.cover/features/tuner/domain/entities/tuner_state.dart';
import 'package:hitwave.cover/features/tuner/domain/repositories/tuner_repository.dart';
import 'package:hitwave.cover/features/tuner/domain/use_cases/start_tuner_use_case.dart';
import 'package:hitwave.cover/features/tuner/domain/use_cases/stop_tuner_use_case.dart';
import 'package:hitwave.cover/features/tuner/domain/use_cases/watch_tuner_use_case.dart';
import 'package:hitwave.cover/features/tuner/presentation/pages/tuner_panel_page.dart';
import 'package:watch_it/watch_it.dart';

/// The tuner without a microphone: the test sets the heard pitch.
final class FakeTunerRepository implements TunerRepository {
  final ValueNotifier<TunerState> state = ValueNotifier<TunerState>(TunerState.off);
  TunerFailure? failure;
  int starts = 0;
  int stops = 0;

  @override
  ValueListenable<TunerState> watchTuner() => state;

  @override
  Future<Result<void, TunerFailure>> start() async {
    starts++;
    final TunerFailure? current = failure;
    if (current != null) return Result.failure(current);
    state.value = const ListeningTunerState(null);
    return Result.ok;
  }

  @override
  Future<void> stop() async {
    stops++;
    state.value = TunerState.off;
  }
}

void main() {
  late FakeTunerRepository repository;

  setUp(() {
    repository = FakeTunerRepository();
    di
      ..registerSingleton<WatchTunerUseCase>(WatchTunerUseCase(repository))
      ..registerSingleton<StartTunerUseCase>(StartTunerUseCase(repository))
      ..registerSingleton<StopTunerUseCase>(StopTunerUseCase(repository));
  });

  tearDown(() => di.reset());

  Future<void> show(WidgetTester tester, {bool shown = true}) => tester.pumpWidget(
    MaterialApp(
      locale: const Locale('en'),
      supportedLocales: const <Locale>[Locale('en'), Locale('isv')],
      localizationsDelegates: const <LocalizationsDelegate<Object>>[
        TranslationsDelegate(),
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ],
      home: Scaffold(body: shown ? const TunerPanelPage() : const SizedBox()),
    ),
  );

  testWidgets('starts listening, shows the string and frees the microphone when it goes', (WidgetTester tester) async {
    await show(tester);
    await tester.pumpAndSettle();
    expect(repository.starts, 1);
    expect(find.text('Play a string'), findsOneWidget);

    repository.state.value = const ListeningTunerState(108);
    await tester.pumpAndSettle();
    expect(find.text('Tune up'), findsOneWidget);
    expect(find.textContaining('108.0 Hz'), findsOneWidget);

    await tester.tap(find.text('Ukulele'));
    repository.state.value = const ListeningTunerState(440);
    await tester.pumpAndSettle();
    expect(find.text('In tune'), findsOneWidget);
    // The big note of the meter and the string of the ukulele.
    expect(find.text('A4'), findsNWidgets(2));

    await show(tester, shown: false);
    await tester.pump();
    expect(repository.stops, 1);
  });

  testWidgets('without the microphone a retry starts again', (WidgetTester tester) async {
    repository.failure = TunerFailure.microphonePermission;
    await show(tester);
    await tester.pumpAndSettle();
    expect(find.text('Allow the microphone to use the tuner.'), findsOneWidget);

    repository.failure = null;
    await tester.tap(find.text('Try again'));
    await tester.pumpAndSettle();

    expect(repository.starts, 2);
    expect(find.text('Play a string'), findsOneWidget);
  });
}
