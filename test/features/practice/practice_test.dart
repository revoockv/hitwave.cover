import 'dart:async';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hitwave.cover/core/data/data_sources/local_storage_service.dart';
import 'package:hitwave.cover/features/practice/data/data_sources/hive_practice_service.dart';
import 'package:hitwave.cover/features/practice/data/repositories/practice_repository_impl.dart';
import 'package:hitwave.cover/features/practice/domain/entities/practice_session.dart';
import 'package:hitwave.cover/features/practice/domain/entities/practice_stats.dart';
import 'package:hitwave.cover/features/recordings/data/data_sources/hive_recording_preferences_service.dart';
import 'package:hitwave.cover/features/recordings/data/repositories/recording_preferences_repository_impl.dart';
import 'package:hitwave.cover/features/recordings/domain/entities/recording.dart';
import 'package:hitwave.cover/features/recordings/domain/entities/recording_preferences.dart';
import 'package:hitwave.cover/features/recordings/domain/entities/recording_status.dart';
import 'package:hitwave.cover/features/song/domain/entities/song_id_change.dart';
import 'package:hitwave.cover/features/song/domain/repositories/song_repository.dart';
import 'package:hive_ce/hive_ce.dart';
import 'package:logger/logger.dart';

/// Only the song id changes of the song repository.
final class FakeSongs implements SongRepository {
  final StreamController<SongIdChange> changes = StreamController<SongIdChange>.broadcast();

  @override
  Stream<SongIdChange> watchSongIdChanges() => changes.stream;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

PracticeSession session(String songId, DateTime at, int minutes) => PracticeSession(
  id: '$songId$at',
  songId: songId,
  startedAt: at,
  duration: Duration(minutes: minutes),
);

Recording take(String songId, DateTime at) => Recording(
  id: '$songId$at',
  songId: songId,
  recordedAt: at,
  durationSeconds: 60,
  rawPath: '',
  enhancedPath: null,
  keptFromSeconds: 0,
  keptToSeconds: null,
  status: RecordingStatus.enhanced,
  enhanceError: null,
);

void main() {
  group('stats', () {
    // Thursday, 12 November 2026.
    final DateTime now = DateTime(2026, 11, 12, 20);

    test('totals of the week, the month and all time; streaks; days with their songs', () {
      final PracticeStats stats = PracticeStats.from(
        sessions: <PracticeSession>[
          session('a', DateTime(2026, 11, 12, 9), 20),
          session('b', DateTime(2026, 11, 12, 10), 5),
          session('a', DateTime(2026, 11, 11, 9), 10),
          session('a', DateTime(2026, 11, 10, 9), 10),
          session('a', DateTime(2026, 11, 8, 9), 15), // Sunday: last week, this month
          session('b', DateTime(2026, 10, 1, 9), 30),
          session('b', DateTime(2026, 10, 2, 9), 30),
          session('b', DateTime(2026, 10, 3, 9), 30),
          session('b', DateTime(2026, 10, 4, 9), 30),
        ],
        recordings: <Recording>[take('a', DateTime(2026, 11, 12, 9, 5)), take('c', DateTime(2026, 11, 9, 9))],
        now: now,
      );

      expect(stats.weekTime, const Duration(minutes: 45));
      expect(stats.weekDays, 4); // Mon (a take), Tue, Wed, Thu
      expect(stats.monthTime, const Duration(minutes: 60));
      expect(stats.monthDays, 5);
      expect(stats.totalTime, const Duration(minutes: 180));
      expect(stats.totalSessions, 9);
      expect(stats.totalTakes, 2);
      expect(stats.currentStreak, 5); // 8–12 November
      expect(stats.longestStreak, 5);
      final today = stats.days[DateTime(2026, 11, 12)]!;
      expect(today.time, const Duration(minutes: 25));
      expect(today.takes, 1);
      expect(today.songs.map((s) => s.songId), <String>['a', 'b']);
      expect(stats.topSongs.first.songId, 'b');
    });

    test('the streak still counts until today ends without practice', () {
      final PracticeStats stats = PracticeStats.from(
        sessions: <PracticeSession>[
          session('a', DateTime(2026, 11, 11, 9), 10),
          session('a', DateTime(2026, 11, 10, 9), 10),
        ],
        recordings: const <Recording>[],
        now: now,
      );
      expect(stats.currentStreak, 2);

      final PracticeStats broken = PracticeStats.from(
        sessions: <PracticeSession>[session('a', DateTime(2026, 11, 10, 9), 10)],
        recordings: const <Recording>[],
        now: now,
      );
      expect(broken.currentStreak, 0);
      expect(broken.longestStreak, 1);
    });
  });

  group('storage', () {
    late Directory directory;
    late FakeSongs songs;
    late DateTime clock;

    setUp(() async {
      directory = await Directory.systemTemp.createTemp('hitwave_practice_test');
      Hive.init(directory.path);
      songs = FakeSongs();
      clock = DateTime(2026, 11, 12, 10);
    });

    tearDown(() async {
      await Hive.close();
      await directory.delete(recursive: true);
    });

    Future<PracticeRepositoryImpl> open() async => PracticeRepositoryImpl(
      store: await HivePracticeService(storage: LocalStorageService()).init(),
      songs: songs,
      logger: Logger(level: Level.off),
      now: () => clock,
    ).init();

    test('a session is kept when long enough and survives a restart', () async {
      final PracticeRepositoryImpl repository = await open();

      await repository.startPractice('song-1');
      clock = clock.add(const Duration(seconds: 5));
      await repository.stopPractice();
      expect(repository.watchSessions().value, isEmpty);

      await repository.startPractice('song-1');
      await repository.startPractice('song-1'); // pressed again while running: same session
      clock = clock.add(const Duration(minutes: 3));
      await repository.stopPractice();
      await repository.stopPractice(); // nothing running

      final PracticeSession kept = repository.watchSessions().value.single;
      expect(kept.duration, const Duration(minutes: 3));

      await Hive.close();
      Hive.init(directory.path);
      expect((await open()).watchSessions().value.single.duration, const Duration(minutes: 3));
    });

    test('sessions follow a song moved into the account and go with a deleted one', () async {
      final PracticeRepositoryImpl repository = await open();
      for (final String id in <String>['local-1', 'local-2']) {
        await repository.startPractice(id);
        clock = clock.add(const Duration(minutes: 1));
      }
      await repository.stopPractice();

      songs.changes.add(const SongMovedIdChange(fromId: 'local-1', toId: 'account-1'));
      songs.changes.add(const SongDeletedIdChange('local-2'));
      await Future<void>.delayed(const Duration(milliseconds: 50));

      expect(repository.watchSessions().value.single.songId, 'account-1');
    });

    test('the recording checkboxes are remembered', () async {
      Future<RecordingPreferencesRepositoryImpl> openPreferences() async => RecordingPreferencesRepositoryImpl(
        store: await HiveRecordingPreferencesService(storage: LocalStorageService()).init(),
        logger: Logger(level: Level.off),
      ).init();

      final RecordingPreferencesRepositoryImpl preferences = await openPreferences();
      expect(preferences.watchRecordingPreferences().value.record, isFalse);
      expect(preferences.watchRecordingPreferences().value.trimSilence, isTrue);

      await preferences.updateRecordingPreferences(const RecordingPreferences(record: true, trimSilence: false));
      await Hive.close();
      Hive.init(directory.path);

      final RecordingPreferences restored = (await openPreferences()).watchRecordingPreferences().value;
      expect(restored.record, isTrue);
      expect(restored.trimSilence, isFalse);
    });
  });
}
