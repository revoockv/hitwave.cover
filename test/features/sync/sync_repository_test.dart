import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hitwave.cover/core/domain/entities/result.dart';
import 'package:hitwave.cover/features/history/domain/entities/usage_history.dart';
import 'package:hitwave.cover/features/history/domain/repositories/history_repository.dart';
import 'package:hitwave.cover/features/practice/domain/entities/practice_session.dart';
import 'package:hitwave.cover/features/practice/domain/repositories/practice_repository.dart';
import 'package:hitwave.cover/features/recordings/domain/entities/imported_recording.dart';
import 'package:hitwave.cover/features/recordings/domain/entities/recording.dart';
import 'package:hitwave.cover/features/recordings/domain/entities/recording_status.dart';
import 'package:hitwave.cover/features/recordings/domain/repositories/recordings_repository.dart';
import 'package:hitwave.cover/features/song/domain/entities/cover.dart';
import 'package:hitwave.cover/features/song/domain/entities/song.dart';
import 'package:hitwave.cover/features/song/domain/repositories/song_repository.dart';
import 'package:hitwave.cover/features/sync/data/data_sources/sync_client_data_source.dart';
import 'package:hitwave.cover/features/sync/data/data_sources/sync_server_data_source.dart';
import 'package:hitwave.cover/features/sync/data/repositories/sync_repository_impl.dart';
import 'package:hitwave.cover/features/sync/domain/entities/sync_state.dart';
import 'package:logger/logger.dart';

Song song(String id, String author, String name) =>
    Song(id: id, author: author, name: name, lyrics: 'la la', covers: const <Cover>[]);

/// Songs in memory; added songs get the ids `new-1`, `new-2`…
final class FakeSongs implements SongRepository {
  final ValueNotifier<List<Song>> songs;
  int _next = 0;

  FakeSongs(List<Song> initial) : songs = ValueNotifier<List<Song>>(initial);

  @override
  ValueListenable<List<Song>> watchSongs() => songs;

  @override
  Future<Result<List<String>>> addSongs(List<Song> added) async {
    final List<String> ids = <String>[for (final Song _ in added) 'new-${++_next}'];
    songs.value = <Song>[
      ...songs.value,
      for (int i = 0; i < added.length; i++)
        Song(
          id: ids[i],
          author: added[i].author,
          name: added[i].name,
          lyrics: added[i].lyrics,
          covers: const <Cover>[],
        ),
    ];
    return Result.success(ids);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

/// Recordings in a folder of their own; imports move the files in.
final class FakeRecordings implements RecordingsRepository {
  final Directory folder;
  final ValueNotifier<List<Recording>> recordings = ValueNotifier<List<Recording>>(const <Recording>[]);

  FakeRecordings(this.folder);

  Recording add(String id, String songId, {required bool enhanced}) {
    final File raw = File('${folder.path}/${id}_raw.wav')..writeAsBytesSync(<int>[1, 2, 3]);
    final File? better = enhanced ? (File('${folder.path}/${id}_enhanced.wav')..writeAsBytesSync(<int>[4, 5])) : null;
    final Recording recording = Recording(
      id: id,
      songId: songId,
      recordedAt: DateTime(2026, 11, 12, 9),
      durationSeconds: 30,
      rawPath: raw.path,
      enhancedPath: better?.path,
      keptFromSeconds: 1,
      keptToSeconds: 29,
      status: enhanced ? RecordingStatus.enhanced : RecordingStatus.enhanceFailed,
      enhanceError: null,
    );
    recordings.value = <Recording>[...recordings.value, recording];
    return recording;
  }

  @override
  ValueListenable<List<Recording>> watchRecordings() => recordings;

  @override
  Future<Result<void>> importRecordings(List<ImportedRecording> imported) async {
    for (final ImportedRecording recording in imported) {
      final String id = recording.id!;
      final String raw = '${folder.path}/${id}_raw.wav';
      await File(recording.rawFilePath).rename(raw);
      final String? enhancedFile = recording.enhancedFilePath;
      final String? enhanced = enhancedFile == null ? null : '${folder.path}/${id}_enhanced.wav';
      if (enhancedFile != null) await File(enhancedFile).rename(enhanced!);
      recordings.value = <Recording>[
        ...recordings.value,
        Recording(
          id: id,
          songId: recording.songId,
          recordedAt: recording.recordedAt,
          durationSeconds: recording.durationSeconds,
          rawPath: raw,
          enhancedPath: enhanced,
          keptFromSeconds: recording.keptFromSeconds,
          keptToSeconds: recording.keptToSeconds,
          status: enhanced == null ? RecordingStatus.enhancing : RecordingStatus.enhanced,
          enhanceError: null,
        ),
      ];
    }
    return Result.ok;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

/// Practice sessions in memory.
final class FakePractice implements PracticeRepository {
  final ValueNotifier<List<PracticeSession>> sessions;

  FakePractice(List<PracticeSession> initial) : sessions = ValueNotifier<List<PracticeSession>>(initial);

  @override
  ValueListenable<List<PracticeSession>> watchSessions() => sessions;

  @override
  Future<Result<void>> importSessions(List<PracticeSession> added) async {
    sessions.value = <PracticeSession>[...sessions.value, ...added];
    return Result.ok;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

/// History in memory.
final class FakeHistory implements HistoryRepository {
  final ValueNotifier<UsageHistory> history;

  FakeHistory(UsageHistory initial) : history = ValueNotifier<UsageHistory>(initial);

  @override
  ValueListenable<UsageHistory> watchHistory() => history;

  @override
  Future<Result<void>> importHistory(UsageHistory added) async {
    history.value = UsageHistory(
      songsOpenedAt: <String, DateTime>{...history.value.songsOpenedAt, ...added.songsOpenedAt},
      coversPlayedAt: <String, DateTime>{...history.value.coversPlayedAt, ...added.coversPlayedAt},
    );
    return Result.ok;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

/// One device: its data and its sync repository.
final class Device {
  final FakeSongs songs;
  final FakeRecordings recordings;
  final FakePractice practice;
  final FakeHistory history;
  late final SyncRepositoryImpl sync = SyncRepositoryImpl(
    songs: songs,
    recordings: recordings,
    practice: practice,
    history: history,
    server: SyncServerDataSource(includeLoopback: true),
    client: SyncClientDataSource(),
    logger: Logger(level: Level.off),
    deviceName: 'test',
  );

  Device({required this.songs, required this.recordings, required this.practice, required this.history});
}

PracticeSession session(String id, String songId) =>
    PracticeSession(id: id, songId: songId, startedAt: DateTime(2026, 11, 12, 9), duration: const Duration(minutes: 5));

void main() {
  late Directory root;

  setUp(() async => root = await Directory.systemTemp.createTemp('hitwave_sync_test'));

  tearDown(() async => root.delete(recursive: true));

  test('two devices exchange what each misses and match songs by artist and name', () async {
    final Device host = Device(
      songs: FakeSongs(<Song>[song('a1', 'Океан Ельзи', 'Обійми')]),
      recordings: FakeRecordings(await Directory('${root.path}/host').create()),
      practice: FakePractice(<PracticeSession>[session('sa', 'a1')]),
      history: FakeHistory(
        UsageHistory(
          songsOpenedAt: <String, DateTime>{'a1': DateTime(2026, 11, 12)},
          coversPlayedAt: const <String, DateTime>{},
        ),
      ),
    );
    host.recordings.add('ra', 'a1', enhanced: true);
    final Device guest = Device(
      songs: FakeSongs(<Song>[song('b1', ' океан ельзи', 'ОБІЙМИ '), song('b2', 'Kalush', 'Stefania')]),
      recordings: FakeRecordings(await Directory('${root.path}/guest').create()),
      practice: FakePractice(<PracticeSession>[session('sb', 'b2')]),
      history: FakeHistory(UsageHistory.empty),
    );
    guest.recordings.add('rb', 'b2', enhanced: false);

    expect((await host.sync.startHosting()).isSuccess, isTrue);
    final String code = (host.sync.watchSyncState().value as HostingSyncState).code;

    expect((await guest.sync.syncWith(code)).isSuccess, isTrue);

    // The guest got the cover and the session of the host's song, which it already had.
    expect(guest.songs.songs.value.length, 2);
    final Recording received = guest.recordings.recordings.value.singleWhere((Recording r) => r.id == 'ra');
    expect(received.songId, 'b1');
    expect(File(received.rawPath).readAsBytesSync(), <int>[1, 2, 3]);
    expect(File(received.enhancedPath!).readAsBytesSync(), <int>[4, 5]);
    expect(guest.practice.sessions.value.map((PracticeSession s) => s.songId), containsAll(<String>['b1', 'b2']));
    expect(guest.history.history.value.songsOpenedAt.keys, <String>['b1']);

    // The host got the song it missed, with its cover and session.
    expect(host.songs.songs.value.map((Song s) => s.name), <String>['Обійми', 'Stefania']);
    final Recording sent = host.recordings.recordings.value.singleWhere((Recording r) => r.id == 'rb');
    expect(sent.songId, 'new-1');
    expect(sent.enhancedPath, isNull);
    expect(host.practice.sessions.value.singleWhere((PracticeSession s) => s.id == 'sb').songId, 'new-1');

    final DoneSyncState guestDone = guest.sync.watchSyncState().value as DoneSyncState;
    expect(guestDone.summary.songsReceived, 0);
    expect(guestDone.summary.coversReceived, 1);
    expect(guestDone.summary.songsSent, 1);
    expect(guestDone.summary.coversSent, 1);
    final DoneSyncState hostDone = host.sync.watchSyncState().value as DoneSyncState;
    expect(hostDone.summary.songsReceived, 1);
    expect(hostDone.summary.coversSent, 1);

    // A second run adds nothing new.
    await host.sync.stopSync();
    await host.sync.startHosting();
    await guest.sync.syncWith((host.sync.watchSyncState().value as HostingSyncState).code);
    final DoneSyncState again = guest.sync.watchSyncState().value as DoneSyncState;
    expect(again.summary.coversReceived + again.summary.coversSent + again.summary.songsSent, 0);

    await host.sync.stopSync();
  });

  test('a wrong code or a wrong key fails without touching anything', () async {
    final Device guest = Device(
      songs: FakeSongs(const <Song>[]),
      recordings: FakeRecordings(await Directory('${root.path}/guest').create()),
      practice: FakePractice(const <PracticeSession>[]),
      history: FakeHistory(UsageHistory.empty),
    );

    expect((await guest.sync.syncWith('not a code')).isFailure, isTrue);
    expect(guest.sync.watchSyncState().value, isA<FailedSyncState>());
  });
}
