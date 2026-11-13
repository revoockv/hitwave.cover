import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart' show ValueNotifier;
import 'package:flutter_test/flutter_test.dart';
import 'package:hitwave.cover/core/data/data_sources/local_storage_service.dart';
import 'package:hitwave.cover/core/domain/entities/result.dart';
import 'package:hitwave.cover/features/auth/domain/entities/auth_session.dart';
import 'package:hitwave.cover/features/auth/domain/entities/user.dart';
import 'package:hitwave.cover/features/song/data/data_sources/hive_song_service.dart';
import 'package:hitwave.cover/features/song/data/data_sources/song_data_source.dart';
import 'package:hitwave.cover/features/song/data/models/cover_model.dart';
import 'package:hitwave.cover/features/song/data/models/song_model.dart';
import 'package:hitwave.cover/features/song/data/repositories/song_repository_impl.dart';
import 'package:hive_ce/hive_ce.dart';
import 'package:logger/logger.dart';
import 'package:hitwave.cover/features/song/domain/entities/song_failure.dart';

/// Songs of an account kept in memory instead of Firestore.
final class FakeAccountSongs implements SongDataSource {
  final List<SongModel> songs = <SongModel>[];

  final StreamController<List<SongModel>> _changes = StreamController<List<SongModel>>.broadcast();

  @override
  Stream<List<SongModel>> watchSongs() async* {
    yield List<SongModel>.of(songs);
    yield* _changes.stream;
  }

  @override
  Future<String> addSong(SongModel song) async {
    final String id = 'a${songs.length}';
    songs.add(
      SongModel(
        id: id,
        author: song.author,
        name: song.name,
        album: song.album,
        lyrics: song.lyrics,
        coverIds: const <String>[],
        scrollSpeed: song.scrollSpeed,
        leadIn: song.leadIn,
      ),
    );
    _changes.add(List<SongModel>.of(songs));
    return id;
  }

  @override
  Future<List<CoverModel>> getCovers(String songId) async => const <CoverModel>[];

  @override
  Future<String> addCover({required String songId, required CoverModel cover}) async => 'c';

  @override
  Future<void> updateSong(SongModel song) async {}

  @override
  Future<void> updateSongScrollSpeed({required String songId, required double speed}) async {}

  @override
  Future<void> updateSongLeadIn({required String songId, required double leadIn}) async {}

  @override
  Future<void> updateSongLyrics({required String songId, required String lyrics}) async {}

  @override
  Future<void> deleteSong(String songId) async {}

  @override
  Future<void> updateCover({required String songId, required CoverModel cover}) async {}

  @override
  Future<void> deleteCover({required String songId, required String coverId}) async {}
}

const SignedInAuthSession _signedIn = SignedInAuthSession(User(id: 'u1', email: 'a@b.c'));

/// Lets Hive writes, box events and the repository's async work finish.
Future<void> _settle() => Future<void>.delayed(const Duration(milliseconds: 100));

void main() {
  late Directory directory;
  late HiveSongService localSongs;
  late FakeAccountSongs accountSongs;
  late ValueNotifier<AuthSession> session;
  late SongRepositoryImpl repository;

  setUp(() async {
    directory = await Directory.systemTemp.createTemp('hitwave_hive_test');
    Hive.init(directory.path);
    localSongs = await HiveSongService(storage: LocalStorageService()).init();
    accountSongs = FakeAccountSongs();
    session = ValueNotifier<AuthSession>(const GuestAuthSession());
    repository = await SongRepositoryImpl(
      accountSongsOf: (String userId) => accountSongs,
      localSongService: localSongs,
      session: session,
      logger: Logger(level: Level.off),
    ).init();
  });

  tearDown(() async {
    await repository.dispose();
    await Hive.close();
    await directory.delete(recursive: true);
  });

  test('a guest keeps songs on the device with their speed and space', () async {
    await repository.addSong(author: 'Thorinshield', name: 'One Girl', lyrics: 'la');
    await _settle();
    final String id = repository.watchSongs().value.single.id;

    await repository.updateSongLeadIn(songId: id, leadIn: 0.1);
    await repository.updateSongLyrics(songId: id, lyrics: 'la la');
    await _settle();

    expect(repository.watchSongs().value.single.leadIn, 0.1);
    expect(localSongs.readSongs().single.lyrics, 'la la');
    expect(accountSongs.songs, isEmpty);
  });

  test('nobody signed in has no songs and cannot add one', () async {
    session.value = const SignedOutAuthSession();
    await _settle();

    final Result<void, SongFailure> result = await repository.addSong(author: 'A', name: 'B', lyrics: 'c');

    expect(result.isFailure, isTrue);
    expect(repository.watchSongs().value, isEmpty);
  });

  test('after a sign-in the songs on the device are offered and moved', () async {
    await repository.addSong(author: 'A', name: 'B', lyrics: 'c');
    await _settle();

    session.value = _signedIn;
    await _settle();
    expect(repository.watchLocalSongsToTransfer().value, 1);

    final Result<void, SongFailure> result = await repository.transferLocalSongs();
    await _settle();

    expect(result.isSuccess, isTrue);
    expect(accountSongs.songs.single.name, 'B');
    expect(localSongs.songCount, 0);
    expect(repository.watchLocalSongsToTransfer().value, 0);
    expect(repository.watchSongs().value.single.name, 'B');
  });

  test('kept songs are not offered again until they change', () async {
    await repository.addSong(author: 'A', name: 'B', lyrics: 'c');
    await _settle();
    session.value = _signedIn;
    await _settle();

    await repository.keepLocalSongs();
    expect(repository.watchLocalSongsToTransfer().value, 0);

    session.value = const GuestAuthSession();
    await _settle();
    session.value = _signedIn;
    await _settle();
    expect(repository.watchLocalSongsToTransfer().value, 0);

    session.value = const GuestAuthSession();
    await _settle();
    await repository.addSong(author: 'A', name: 'D', lyrics: 'e');
    session.value = _signedIn;
    await _settle();
    expect(repository.watchLocalSongsToTransfer().value, 2);
  });
}
