import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hitwave.cover/core/data/data_sources/local_storage_service.dart';
import 'package:hitwave.cover/core/domain/entities/result.dart';
import 'package:hitwave.cover/features/song/data/data_sources/hive_song_service.dart';
import 'package:hitwave.cover/features/song/data/repositories/song_repository_impl.dart';
import 'package:hitwave.cover/features/song/domain/entities/cover.dart';
import 'package:hitwave.cover/features/song/domain/entities/lyrics_layout.dart';
import 'package:hitwave.cover/features/song/domain/entities/song.dart';
import 'package:hitwave.cover/features/song/domain/entities/song_failure.dart';
import 'package:hitwave.cover/features/song/domain/entities/song_id_change.dart';
import 'package:hive_ce/hive_ce.dart';
import 'package:logger/logger.dart';

/// Lets Hive writes, box events and the repository's async work finish.
Future<void> _settle() => Future<void>.delayed(const Duration(milliseconds: 100));

Song _song(String name) => Song(id: '', author: 'A', name: name, lyrics: 'la', covers: const <Cover>[]);

void main() {
  late Directory directory;
  late HiveSongService localSongs;
  late SongRepositoryImpl repository;

  Future<SongRepositoryImpl> open() async => SongRepositoryImpl(
    dataSource: localSongs,
    logger: Logger(level: Level.off),
  ).init();

  setUp(() async {
    directory = await Directory.systemTemp.createTemp('hitwave_hive_test');
    Hive.init(directory.path);
    localSongs = await HiveSongService(storage: LocalStorageService()).init();
    repository = await open();
  });

  tearDown(() async {
    await repository.dispose();
    await Hive.close();
    await directory.delete(recursive: true);
  });

  test('songs are kept on the device with their speed and space', () async {
    await repository.addSong(author: 'Thorinshield', name: 'One Girl', lyrics: 'la');
    await _settle();
    final String id = repository.watchSongs().value.single.id;

    await repository.updateSongLeadIn(songId: id, layout: LyricsLayout.compact, leadIn: 0.1);
    await repository.updateSongLyrics(songId: id, lyrics: 'la la');
    await _settle();

    expect(repository.watchSongs().value.single.leadIn, 0.1);
    expect(localSongs.readSongs().single.lyrics, 'la la');
  });

  test('a big screen takes the phone speed and space until it has its own', () async {
    await repository.addSong(author: 'A', name: 'B', lyrics: 'c');
    await _settle();
    final String id = repository.watchSongs().value.single.id;
    await repository.updateSongScrollSpeed(songId: id, layout: LyricsLayout.compact, speed: 0.3);
    await repository.updateSongLeadIn(songId: id, layout: LyricsLayout.compact, leadIn: 0.2);
    await _settle();

    Song song = repository.watchSongs().value.single;
    expect((song.scrollSpeedOn(LyricsLayout.wide), song.leadInOn(LyricsLayout.wide)), (0.3, 0.2));

    await repository.updateSongScrollSpeed(songId: id, layout: LyricsLayout.wide, speed: 0.6);
    await repository.updateSongLeadIn(songId: id, layout: LyricsLayout.wide, leadIn: 0.5);
    await _settle();

    song = repository.watchSongs().value.single;
    expect((song.scrollSpeedOn(LyricsLayout.wide), song.leadInOn(LyricsLayout.wide)), (0.6, 0.5));
    expect((song.scrollSpeedOn(LyricsLayout.compact), song.leadInOn(LyricsLayout.compact)), (0.3, 0.2));
  });

  test('the songs survive a restart', () async {
    await repository.addSong(author: 'A', name: 'B', lyrics: 'c');
    await _settle();
    await repository.dispose();

    repository = await open();
    await _settle();

    expect(repository.watchSongs().value.single.name, 'B');
  });

  test('deleting all songs tells every deletion to the other features', () async {
    final List<SongIdChange> changes = <SongIdChange>[];
    repository.watchSongIdChanges().listen(changes.add);
    await repository.addSongs(<String>['One', 'Two'].map(_song).toList());
    await _settle();

    final Result<void, SongFailure> result = await repository.deleteAllSongs();
    await _settle();

    expect(result.isSuccess, isTrue);
    expect(repository.watchSongs().value, isEmpty);
    expect(changes.whereType<SongDeletedIdChange>().map((SongDeletedIdChange c) => c.name), <String>['One', 'Two']);
  });
}
