import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hitwave.cover/core/data/data_sources/local_storage_service.dart';
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
import 'package:hitwave.cover/features/song/domain/entities/lyrics_layout.dart';
import 'package:hitwave.cover/features/song/domain/entities/song.dart';
import 'package:hitwave.cover/features/song/domain/entities/song_id_change.dart';
import 'package:hitwave.cover/features/song/domain/repositories/song_repository.dart';
import 'package:hitwave.cover/features/sync/data/data_sources/hive_sync_tombstone_service.dart';
import 'package:hitwave.cover/features/sync/data/data_sources/sync_client_data_source.dart';
import 'package:hitwave.cover/features/sync/data/data_sources/sync_server_data_source.dart';
import 'package:hitwave.cover/features/sync/data/repositories/sync_repository_impl.dart';
import 'package:hitwave.cover/features/sync/domain/entities/sync_conflict.dart';
import 'package:hitwave.cover/features/sync/domain/entities/sync_state.dart';
import 'package:hive_ce/hive_ce.dart';
import 'package:logger/logger.dart';
import 'package:hitwave.cover/features/song/domain/entities/song_failure.dart';
import 'package:hitwave.cover/features/recordings/domain/entities/recordings_failure.dart';
import 'package:hitwave.cover/features/practice/domain/entities/practice_failure.dart';
import 'package:hitwave.cover/features/history/domain/entities/history_failure.dart';
import 'package:hitwave.cover/features/sync/domain/entities/sync_failure.dart';
import 'package:hitwave.cover/features/sync/domain/entities/song_difference.dart';
import 'package:hitwave.cover/features/sync/domain/entities/sync_step.dart';

Song song(String id, String author, String name, {String lyrics = 'la la', double? speed}) =>
    Song(id: id, author: author, name: name, lyrics: lyrics, covers: const <Cover>[], scrollSpeed: speed);

/// Songs in memory; added songs get the ids `new-1`, `new-2`…
final class FakeSongs implements SongRepository {
  final ValueNotifier<List<Song>> songs;
  final StreamController<SongIdChange> changes = StreamController<SongIdChange>.broadcast();
  int _next = 0;

  FakeSongs(List<Song> initial) : songs = ValueNotifier<List<Song>>(initial);

  @override
  ValueListenable<List<Song>> watchSongs() => songs;

  @override
  Stream<SongIdChange> watchSongIdChanges() => changes.stream;

  @override
  Future<Result<List<String>, SongFailure>> addSongs(List<Song> added) async {
    final List<String> ids = <String>[for (final Song _ in added) 'new-${++_next}'];
    songs.value = <Song>[
      ...songs.value,
      for (int i = 0; i < added.length; i++) song(ids[i], added[i].author, added[i].name, lyrics: added[i].lyrics),
    ];
    return Result.success(ids);
  }

  @override
  Future<Result<void, SongFailure>> deleteSong({required String songId}) async {
    final Song deleted = songs.value.singleWhere((Song s) => s.id == songId);
    songs.value = songs.value.where((Song s) => s.id != songId).toList();
    changes.add(SongDeletedIdChange(songId, author: deleted.author, name: deleted.name));
    return Result.ok;
  }

  @override
  Future<Result<void, SongFailure>> updateSong({
    required String songId,
    required String author,
    required String name,
    String? album,
    required String lyrics,
  }) async {
    songs.value = <Song>[
      for (final Song s in songs.value) s.id == songId ? song(s.id, author, name, lyrics: lyrics) : s,
    ];
    return Result.ok;
  }

  @override
  Future<Result<void, SongFailure>> updateSongScrollSpeed({
    required String songId,
    required LyricsLayout layout,
    required double speed,
  }) async => Result.ok;

  @override
  Future<Result<void, SongFailure>> updateSongLeadIn({
    required String songId,
    required LyricsLayout layout,
    required double leadIn,
  }) async => Result.ok;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

/// Recordings in a folder of their own; imports move the files in.
final class FakeRecordings implements RecordingsRepository {
  final Directory folder;
  final ValueNotifier<List<Recording>> recordings = ValueNotifier<List<Recording>>(const <Recording>[]);
  final StreamController<String> deletions = StreamController<String>.broadcast();

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
      enhanceFailure: null,
    );
    recordings.value = <Recording>[...recordings.value, recording];
    return recording;
  }

  @override
  ValueListenable<List<Recording>> watchRecordings() => recordings;

  @override
  Stream<String> watchRecordingDeletions() => deletions.stream;

  @override
  ValueListenable<String?> watchEnhancingRecording() => ValueNotifier<String?>(null);

  @override
  Future<Result<void, RecordingsFailure>> deleteRecording(String recordingId) async {
    recordings.value = recordings.value.where((Recording r) => r.id != recordingId).toList();
    deletions.add(recordingId);
    return Result.ok;
  }

  @override
  Future<Result<void, RecordingsFailure>> importRecordings(List<ImportedRecording> imported) async {
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
          enhanceFailure: null,
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
  Future<Result<void, PracticeFailure>> importSessions(List<PracticeSession> added) async {
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
  Future<Result<void, HistoryFailure>> importHistory(UsageHistory added) async {
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
  final SyncRepositoryImpl sync;

  Device._(this.songs, this.recordings, this.practice, this.history, this.sync);

  static Future<Device> create({
    required String name,
    required List<Song> songs,
    required Directory root,
    List<PracticeSession> sessions = const <PracticeSession>[],
    UsageHistory history = UsageHistory.empty,
  }) async {
    final FakeSongs fakeSongs = FakeSongs(songs);
    final FakeRecordings recordings = FakeRecordings(await Directory('${root.path}/$name').create());
    final FakePractice practice = FakePractice(sessions);
    final FakeHistory fakeHistory = FakeHistory(history);
    final HiveSyncTombstoneService tombstones = await HiveSyncTombstoneService(
      storage: LocalStorageService(),
      boxName: 'tombstones_$name',
    ).init();
    final SyncRepositoryImpl sync = SyncRepositoryImpl(
      songs: fakeSongs,
      recordings: recordings,
      practice: practice,
      history: fakeHistory,
      tombstones: tombstones,
      server: SyncServerDataSource(includeLoopback: true),
      client: SyncClientDataSource(deviceName: name),
      logger: Logger(level: Level.off),
      deviceName: name,
    ).init();
    return Device._(fakeSongs, recordings, practice, fakeHistory, sync);
  }

  /// Hosts a synchronisation and lets [guest] scan its code.
  Future<void> hostFor(Device guest) async {
    await sync.stopSync();
    await guest.sync.stopSync();
    expect((await sync.startHosting()).isSuccess, isTrue);
    expect((await guest.sync.syncWith((sync.watchSyncState().value as HostingSyncState).code)).isSuccess, isTrue);
  }

  List<String> get songNames => songs.songs.value.map((Song s) => s.name).toList();

  List<String> get coverIds => recordings.recordings.value.map((Recording r) => r.id).toList();
}

PracticeSession session(String id, String songId) =>
    PracticeSession(id: id, songId: songId, startedAt: DateTime(2026, 11, 12, 9), duration: const Duration(minutes: 5));

/// Lets the deletion listeners write their tombstones.
Future<void> settle() => Future<void>.delayed(const Duration(milliseconds: 50));

void main() {
  late Directory root;

  setUp(() async {
    root = await Directory.systemTemp.createTemp('hitwave_sync_test');
    Hive.init(root.path);
  });

  tearDown(() async {
    await Hive.close();
    await root.delete(recursive: true);
  });

  test('two devices exchange what each misses and match songs by artist and name', () async {
    final Device host = await Device.create(
      name: 'host',
      root: root,
      songs: <Song>[song('a1', 'Океан Ельзи', 'Обійми')],
      sessions: <PracticeSession>[session('sa', 'a1')],
      history: UsageHistory(
        songsOpenedAt: <String, DateTime>{'a1': DateTime(2026, 11, 12)},
        coversPlayedAt: const <String, DateTime>{},
      ),
    );
    host.recordings.add('ra', 'a1', enhanced: true);
    final Device guest = await Device.create(
      name: 'guest',
      root: root,
      songs: <Song>[song('b1', ' океан ельзи', 'ОБІЙМИ '), song('b2', 'Kalush', 'Stefania')],
      sessions: <PracticeSession>[session('sb', 'b2')],
    );
    guest.recordings.add('rb', 'b2', enhanced: false);

    await host.hostFor(guest);

    // The guest got the cover and the session of the host's song, which it already had.
    expect(guest.songs.songs.value.length, 2);
    final Recording received = guest.recordings.recordings.value.singleWhere((Recording r) => r.id == 'ra');
    expect(received.songId, 'b1');
    expect(File(received.rawPath).readAsBytesSync(), <int>[1, 2, 3]);
    expect(File(received.enhancedPath!).readAsBytesSync(), <int>[4, 5]);
    expect(guest.practice.sessions.value.map((PracticeSession s) => s.songId), containsAll(<String>['b1', 'b2']));
    expect(guest.history.history.value.songsOpenedAt.keys, <String>['b1']);

    // The host got the song it missed, with its cover and session.
    expect(host.songNames, <String>['Обійми', 'Stefania']);
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

    // A second run adds nothing new and finds no conflicts.
    await host.hostFor(guest);
    final DoneSyncState again = guest.sync.watchSyncState().value as DoneSyncState;
    expect(again.summary.coversReceived + again.summary.coversSent + again.summary.songsSent, 0);
    await host.sync.stopSync();
  });

  test('deletions are conflicts the user decides; "delete" removes them on the other device too', () async {
    List<Song> both() => <Song>[song('s', 'A', 'Kept'), song('t', 'B', 'Doomed')];
    final Device host = await Device.create(name: 'host', root: root, songs: both());
    final Device guest = await Device.create(name: 'guest', root: root, songs: both());
    host.recordings.add('c', 's', enhanced: true);
    guest.recordings.add('c', 's', enhanced: true);

    await host.songs.deleteSong(songId: 't'); // deleted on the host
    await guest.recordings.deleteRecording('c'); // deleted on the guest
    await settle();

    await host.hostFor(guest);
    final ConflictsSyncState waiting = guest.sync.watchSyncState().value as ConflictsSyncState;
    expect(waiting.conflicts.map((SyncConflict c) => c.kind), <SyncConflictKind>[
      SyncConflictKind.songDeletedThere,
      SyncConflictKind.coverDeletedHere,
    ]);
    expect(host.sync.watchSyncState().value, isNot(isA<DoneSyncState>()));

    expect(
      (await guest.sync.resolveConflicts(<String, SyncChoice>{
        for (final SyncConflict conflict in waiting.conflicts) conflict.id: SyncChoice.delete,
      })).isSuccess,
      isTrue,
    );

    expect(guest.songNames, <String>['Kept']);
    expect(host.coverIds, isEmpty);
    final DoneSyncState done = guest.sync.watchSyncState().value as DoneSyncState;
    expect(done.summary.deletedHere, 1);
    expect(done.summary.deletedThere, 1);

    // Both now remember the deletions: nothing to ask the next time.
    await settle();
    await host.hostFor(guest);
    expect(guest.sync.watchSyncState().value, isA<DoneSyncState>());
    await host.sync.stopSync();
  });

  test('"restore" brings a deleted song back and a changed song can take the other version', () async {
    final Device host = await Device.create(
      name: 'host',
      root: root,
      songs: <Song>[
        song('u', 'C', 'Lost'),
        song('v', 'D', 'Edited', lyrics: 'new words'),
      ],
    );
    final Device guest = await Device.create(
      name: 'guest',
      root: root,
      songs: <Song>[
        song('u2', 'C', 'Lost'),
        song('v2', 'D', 'Edited', lyrics: 'old words'),
      ],
    );
    guest.recordings.add('cu', 'u2', enhanced: false);
    await host.songs.deleteSong(songId: 'u');
    await settle();

    await host.hostFor(guest);
    final ConflictsSyncState waiting = guest.sync.watchSyncState().value as ConflictsSyncState;
    final SyncConflict deleted = waiting.conflicts.singleWhere(
      (SyncConflict c) => c.kind == SyncConflictKind.songDeletedThere,
    );
    final SyncConflict changed = waiting.conflicts.singleWhere(
      (SyncConflict c) => c.kind == SyncConflictKind.songChanged,
    );
    expect(changed.differences, contains(SongDifference.lyrics));

    await guest.sync.resolveConflicts(<String, SyncChoice>{
      deleted.id: SyncChoice.restore,
      changed.id: SyncChoice.takeOther,
    });

    expect(host.songNames, containsAll(<String>['Lost', 'Edited']));
    expect(host.coverIds, <String>['cu']);
    expect(guest.songs.songs.value.singleWhere((Song s) => s.name == 'Edited').lyrics, 'new words');

    // The host forgot the deletion: no conflict any more.
    await host.hostFor(guest);
    expect(guest.sync.watchSyncState().value, isA<DoneSyncState>());
    await host.sync.stopSync();
  });

  test('the host shows who connected and what it does; a cancel there is a failure here', () async {
    final Device host = await Device.create(name: 'mac', root: root, songs: <Song>[song('s', 'A', 'Gone')]);
    final Device guest = await Device.create(name: 'pixel', root: root, songs: <Song>[song('s2', 'A', 'Gone')]);
    await host.songs.deleteSong(songId: 's');
    await settle();

    await host.hostFor(guest);
    expect(guest.sync.watchSyncState().value, isA<ConflictsSyncState>());
    await settle();
    final SyncingSyncState waiting = host.sync.watchSyncState().value as SyncingSyncState;
    expect(waiting.peerName, '«pixel»');
    expect(waiting.step, SyncStep.choosing);

    await guest.sync.stopSync();
    final FailedSyncState failed = host.sync.watchSyncState().value as FailedSyncState;
    expect(failed.failure, SyncFailure.peerStopped);
    expect(failed.peerFailure, SyncFailure.cancelled);
    expect(guest.songNames, <String>['Gone']);
  });

  test('a song differing only in speed or line endings is no conflict', () async {
    final Device host = await Device.create(
      name: 'host',
      root: root,
      songs: <Song>[song('s', 'A', 'Same', lyrics: 'one\r\ntwo  \n', speed: 2)],
    );
    final Device guest = await Device.create(
      name: 'guest',
      root: root,
      songs: <Song>[song('s2', 'A', 'Same', lyrics: 'one\ntwo', speed: 5)],
    );

    await host.hostFor(guest);

    expect(guest.sync.watchSyncState().value, isA<DoneSyncState>());
    await host.sync.stopSync();
  });

  test('a wrong code fails without touching anything', () async {
    final Device guest = await Device.create(name: 'guest', root: root, songs: const <Song>[]);

    expect((await guest.sync.syncWith('not a code')).isFailure, isTrue);
    expect(guest.sync.watchSyncState().value, isA<FailedSyncState>());
  });
}
