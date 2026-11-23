import 'dart:async';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hitwave.cover/core/data/data_sources/local_storage_service.dart';
import 'package:hitwave.cover/features/history/data/data_sources/hive_history_service.dart';
import 'package:hitwave.cover/features/history/data/repositories/history_repository_impl.dart';
import 'package:hitwave.cover/features/history/domain/entities/usage_history.dart';
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

void main() {
  late Directory directory;
  late FakeSongs songs;
  late DateTime clock;

  setUp(() async {
    directory = await Directory.systemTemp.createTemp('hitwave_history_test');
    Hive.init(directory.path);
    songs = FakeSongs();
    clock = DateTime(2026, 11, 12, 10);
  });

  tearDown(() async {
    await Hive.close();
    await directory.delete(recursive: true);
  });

  Future<HistoryRepositoryImpl> open() async => HistoryRepositoryImpl(
    store: await HiveHistoryService(storage: LocalStorageService()).init(),
    songs: songs,
    logger: Logger(level: Level.off),
    now: () => clock,
  ).init();

  test('openings and playbacks are remembered across restarts', () async {
    final HistoryRepositoryImpl repository = await open();
    await repository.markSongOpened('song-1');
    clock = clock.add(const Duration(minutes: 5));
    await repository.markSongOpened('song-1');
    await repository.markCoverPlayed('cover-1');

    await Hive.close();
    Hive.init(directory.path);
    final UsageHistory history = (await open()).watchHistory().value;

    expect(history.songsOpenedAt['song-1'], DateTime(2026, 11, 12, 10, 5));
    expect(history.coversPlayedAt['cover-1'], DateTime(2026, 11, 12, 10, 5));
  });

  test('openings follow a song moved into the account and go with a deleted one', () async {
    final HistoryRepositoryImpl repository = await open();
    await repository.markSongOpened('local-1');
    await repository.markSongOpened('local-2');

    songs.changes.add(const SongMovedIdChange(fromId: 'local-1', toId: 'account-1'));
    songs.changes.add(const SongDeletedIdChange('local-2'));
    await Future<void>.delayed(const Duration(milliseconds: 50));

    expect(repository.watchHistory().value.songsOpenedAt.keys, <String>['account-1']);
  });

  test('clearing forgets the openings and playbacks, also after a restart', () async {
    final HistoryRepositoryImpl repository = await open();
    await repository.markSongOpened('song-1');
    await repository.markCoverPlayed('cover-1');

    expect((await repository.clearHistory()).isSuccess, isTrue);
    expect(repository.watchHistory().value.songsOpenedAt, isEmpty);
    expect(repository.watchHistory().value.coversPlayedAt, isEmpty);

    await Hive.close();
    Hive.init(directory.path);
    final HistoryRepositoryImpl reopened = await open();
    expect(reopened.watchHistory().value.songsOpenedAt, isEmpty);
    expect(reopened.watchHistory().value.coversPlayedAt, isEmpty);
  });
}
