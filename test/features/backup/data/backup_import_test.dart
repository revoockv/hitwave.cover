import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hitwave.cover/core/data/data_sources/system_files_data_source.dart';
import 'package:hitwave.cover/core/domain/entities/result.dart';
import 'package:hitwave.cover/features/backup/data/data_sources/backup_archive_data_source.dart';
import 'package:hitwave.cover/features/backup/data/data_sources/backup_data_source.dart';
import 'package:hitwave.cover/features/backup/data/repositories/backup_repository_impl.dart';
import 'package:hitwave.cover/features/backup/domain/entities/backup_failure.dart';
import 'package:hitwave.cover/features/backup/domain/entities/import_choice.dart';
import 'package:hitwave.cover/features/backup/domain/entities/import_decision.dart';
import 'package:hitwave.cover/features/backup/domain/entities/import_conflict.dart';
import 'package:hitwave.cover/features/backup/domain/entities/import_plan.dart';
import 'package:hitwave.cover/features/backup/domain/entities/import_summary.dart';
import 'package:hitwave.cover/features/recordings/domain/entities/imported_recording.dart';
import 'package:hitwave.cover/features/recordings/domain/entities/recording.dart';
import 'package:hitwave.cover/features/recordings/domain/entities/recording_status.dart';
import 'package:hitwave.cover/features/recordings/domain/entities/recordings_failure.dart';
import 'package:hitwave.cover/features/recordings/domain/repositories/recordings_repository.dart';
import 'package:hitwave.cover/features/song/domain/entities/cover.dart';
import 'package:hitwave.cover/features/song/domain/entities/song.dart';
import 'package:hitwave.cover/features/song/domain/entities/song_failure.dart';
import 'package:hitwave.cover/features/song/domain/repositories/song_repository.dart';
import 'package:logger/logger.dart';

Song song(String id, String author, String name, {String lyrics = 'la la'}) =>
    Song(id: id, author: author, name: name, lyrics: lyrics, covers: const <Cover>[]);

/// Songs in memory; added songs get the ids `new-1`, `new-2`…
final class FakeSongs implements SongRepository {
  final ValueNotifier<List<Song>> songs;
  int _next = 0;

  FakeSongs(List<Song> initial) : songs = ValueNotifier<List<Song>>(initial);

  @override
  ValueListenable<List<Song>> watchSongs() => songs;

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
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

/// Recordings in memory; imported ones get the ids `take-1`, `take-2`…
final class FakeRecordings implements RecordingsRepository {
  final ValueNotifier<List<Recording>> recordings = ValueNotifier<List<Recording>>(const <Recording>[]);
  int _next = 0;

  @override
  ValueListenable<List<Recording>> watchRecordings() => recordings;

  @override
  Future<Result<void, RecordingsFailure>> importRecordings(List<ImportedRecording> imported) async {
    recordings.value = <Recording>[
      ...recordings.value,
      for (final ImportedRecording recording in imported)
        take('take-${++_next}', recording.songId, recording.recordedAt, rawPath: recording.rawFilePath),
    ];
    return Result.ok;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

Recording take(String id, String songId, DateTime at, {String rawPath = ''}) => Recording(
  id: id,
  songId: songId,
  recordedAt: at,
  durationSeconds: 30,
  rawPath: rawPath,
  enhancedPath: null,
  keptFromSeconds: 0,
  keptToSeconds: null,
  status: RecordingStatus.recorded,
  enhanceFailure: null,
);

/// Gives the file it was made with to the import.
final class FakePicker implements BackupDataSource {
  final PickedBackupFile? file;

  FakePicker(this.file);

  @override
  Future<PickedBackupFile?> pickBackupFile() async => file;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

Map<String, dynamic> backupSong(String id, String author, String name, String lyrics) => <String, dynamic>{
  'id': id,
  'author': author,
  'name': name,
  'album': null,
  'lyrics': lyrics,
  'coverIds': const <String>[],
};

String backupJson(List<Map<String, dynamic>> songs, {List<Map<String, dynamic>> recordings = const []}) =>
    jsonEncode(<String, dynamic>{
      'version': '1.1',
      'exportedAt': DateTime(2026, 11, 16).toIso8601String(),
      'songs': songs,
      if (recordings.isNotEmpty) 'recordings': recordings,
    });

BackupRepositoryImpl repositoryOf(FakeSongs songs, FakeRecordings recordings, PickedBackupFile? file) =>
    BackupRepositoryImpl(
      songRepository: songs,
      recordingsRepository: recordings,
      dataSource: FakePicker(file),
      archive: BackupArchiveDataSource(),
      system: SystemFilesDataSource(),
      logger: Logger(level: Level.off),
    );

PickedBackupFile jsonFile(String json) =>
    PickedBackupFile(name: 'backup.json', path: null, bytes: Uint8List.fromList(utf8.encode(json)));

Future<ImportPlan> open(BackupRepositoryImpl repository, {bool includeRecordings = false}) async {
  final Result<ImportPlan?, BackupFailure> result = await repository.openImport(includeRecordings: includeRecordings);
  return (result as SuccessResult<ImportPlan?, BackupFailure>).value!;
}

Future<ImportSummary> apply(BackupRepositoryImpl repository, Map<int, ImportChoice> choices) async {
  final Result<ImportSummary, BackupFailure> result = await repository.applyImport(<ImportDecision>[
    for (final MapEntry<int, ImportChoice> entry in choices.entries)
      ImportDecision(index: entry.key, choice: entry.value),
  ]);
  return (result as SuccessResult<ImportSummary, BackupFailure>).value;
}

void main() {
  final String file = backupJson(<Map<String, dynamic>>[
    backupSong('b1', 'The Beatles', 'Blackbird', 'new words'),
    backupSong('b2', 'the beatles ', 'SOMETHING', 'same words'),
    backupSong('b3', 'Elvis', 'Devil in disguise', 'elvis words'),
    backupSong('b4', 'The Kinks', 'Sunny afternoon', 'kinks words'),
  ]);

  List<Song> library() => <Song>[
    song('s1', 'The Beatles', 'Blackbird', lyrics: 'old words'),
    song('s2', 'The Beatles', 'Something', lyrics: 'same words'),
    song('s3', 'The Kinks', 'Sunny afternoon', lyrics: 'kinks old'),
    song('s4', 'The Kinks', 'Sunny afternoon (2)', lyrics: 'kinks copy'),
  ];

  test('finds the songs already in the library, with author and name case ignored', () async {
    final FakeSongs songs = FakeSongs(library());
    final ImportPlan plan = await open(repositoryOf(songs, FakeRecordings(), jsonFile(file)));

    expect(plan.songCount, 4);
    expect(plan.conflicts.map((ImportConflict c) => c.index), <int>[0, 1, 3]);
    expect(plan.conflicts.map((ImportConflict c) => c.hasSameLyrics), <bool>[false, true, false]);
    expect(songs.songs.value, hasLength(4));
  });

  test('replaces, keeps both under a free number or skips, as chosen', () async {
    final FakeSongs songs = FakeSongs(library());
    final BackupRepositoryImpl repository = repositoryOf(songs, FakeRecordings(), jsonFile(file));
    await open(repository);

    final ImportSummary summary = await apply(repository, <int, ImportChoice>{
      0: ImportChoice.replace,
      1: ImportChoice.skip,
      3: ImportChoice.keepBoth,
    });

    expect((summary.added, summary.replaced, summary.skipped), (2, 1, 1));
    final Map<String, String> lyricsByName = <String, String>{for (final Song s in songs.songs.value) s.name: s.lyrics};
    expect(lyricsByName['Blackbird'], 'new words');
    expect(lyricsByName['Something'], 'same words');
    expect(lyricsByName['Devil in disguise'], 'elvis words');
    expect(lyricsByName['Sunny afternoon'], 'kinks old');
    expect(lyricsByName['Sunny afternoon (2)'], 'kinks copy');
    expect(lyricsByName['Sunny afternoon (3)'], 'kinks words');
    expect(songs.songs.value, hasLength(6));
  });

  test('a conflict without a choice is skipped', () async {
    final FakeSongs songs = FakeSongs(library());
    final BackupRepositoryImpl repository = repositoryOf(songs, FakeRecordings(), jsonFile(file));
    await open(repository);

    final ImportSummary summary = await apply(repository, const <int, ImportChoice>{});

    expect((summary.added, summary.replaced, summary.skipped), (1, 0, 3));
    expect(songs.songs.value.firstWhere((Song s) => s.id == 's1').lyrics, 'old words');
  });

  test('a cancelled import adds nothing and cannot be applied after', () async {
    final FakeSongs songs = FakeSongs(library());
    final BackupRepositoryImpl repository = repositoryOf(songs, FakeRecordings(), jsonFile(file));
    await open(repository);

    await repository.cancelImport();

    expect(await repository.applyImport(const <ImportDecision>[]), isA<FailureResult<ImportSummary, BackupFailure>>());
    expect(songs.songs.value, hasLength(4));
  });

  test('a replaced song gets only the takes it does not have yet', () async {
    final Directory dir = await Directory.systemTemp.createTemp('import_test_');
    addTearDown(() => dir.delete(recursive: true));
    final DateTime old = DateTime(2026, 11, 1, 10);
    final DateTime fresh = DateTime(2026, 11, 2, 10);
    final File raw = File('${dir.path}/raw.wav')..writeAsBytesSync(<int>[1, 2, 3]);
    Map<String, dynamic> recordingJson(String name, DateTime at) => <String, dynamic>{
      'songId': 'b1',
      'recordedAt': at.toIso8601String(),
      'durationSeconds': 30,
      'keptFromSeconds': 0,
      'keptToSeconds': null,
      'rawFile': 'recordings/$name.wav',
      'enhancedFile': null,
    };
    final String zip = '${dir.path}/backup.zip';
    await BackupArchiveDataSource().writeZip(
      path: zip,
      json: backupJson(
        <Map<String, dynamic>>[backupSong('b1', 'The Beatles', 'Blackbird', 'new words')],
        recordings: <Map<String, dynamic>>[recordingJson('old', old), recordingJson('fresh', fresh)],
      ),
      files: <String, String>{'recordings/old.wav': raw.path, 'recordings/fresh.wav': raw.path},
    );
    final FakeSongs songs = FakeSongs(library());
    final FakeRecordings recordings = FakeRecordings();
    recordings.recordings.value = <Recording>[take('mine', 's1', old)];
    final BackupRepositoryImpl repository = repositoryOf(
      songs,
      recordings,
      PickedBackupFile(name: 'backup.zip', path: zip, bytes: null),
    );
    await open(repository, includeRecordings: true);

    await apply(repository, const <int, ImportChoice>{0: ImportChoice.replace});

    expect(recordings.recordings.value.map((Recording r) => (r.songId, r.recordedAt)), <(String, DateTime)>[
      ('s1', old),
      ('s1', fresh),
    ]);
  });
}
