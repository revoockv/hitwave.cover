import 'package:flutter/foundation.dart' show ValueListenable, ValueNotifier;
import 'package:flutter_test/flutter_test.dart';
import 'package:hitwave.cover/core/domain/entities/result.dart';
import 'package:hitwave.cover/features/song/domain/entities/song.dart';
import 'package:hitwave.cover/features/song/domain/repositories/song_repository.dart';
import 'package:hitwave.cover/features/song/domain/use_cases/add_song_use_case.dart';
import 'package:hitwave.cover/features/song/domain/use_cases/delete_song_use_case.dart';
import 'package:hitwave.cover/features/song/domain/use_cases/watch_list_of_songs_use_case.dart';

/// Records calls instead of storing songs.
final class FakeSongRepository implements SongRepository {
  final List<String> addedNames = <String>[];

  final List<String> deletedIds = <String>[];

  Result<void> nextResult = Result.ok;

  final ValueNotifier<List<Song>> _songs = ValueNotifier<List<Song>>(const <Song>[]);

  /// The same instance on every call — like the real repository.
  @override
  ValueListenable<List<Song>> watchSongs() => _songs;

  @override
  Future<Result<void>> addSong({required String author, required String name, String? album, required String lyrics}) async {
    addedNames.add(name);
    return nextResult;
  }

  @override
  Future<Result<void>> deleteSong({required String songId}) async {
    deletedIds.add(songId);
    return nextResult;
  }

  @override
  Future<Result<void>> updateSongScrollSpeed({required String songId, required double speed}) async => nextResult;

  @override
  Future<Result<void>> updateSong({
    required String songId,
    required String author,
    required String name,
    String? album,
    required String lyrics,
  }) async =>
      nextResult;

  @override
  Future<Result<void>> addCover({required String songId, required List<int> audioBytes, String? notes}) async => nextResult;

  @override
  Future<Result<void>> updateCover({
    required String songId,
    required String coverId,
    required List<int> audioBytes,
    String? notes,
  }) async =>
      nextResult;

  @override
  Future<Result<void>> deleteCover({required String songId, required String coverId}) async => nextResult;
}

void main() {
  late FakeSongRepository repository;

  setUp(() {
    repository = FakeSongRepository();
  });

  test('add song passes the song to the repository', () async {
    final Result<void> result = await AddSongUseCase(repository)(author: 'Thorinshield', name: 'One Girl', lyrics: 'la');

    expect(result.isSuccess, isTrue);
    expect(repository.addedNames, <String>['One Girl']);
  });

  test('delete song returns the failure of the repository', () async {
    repository.nextResult = const Result.failure('Помилка при видаленні пісні.');

    final Result<void> result = await DeleteSongUseCase(repository)(songId: 's1');

    expect(result.isFailure, isTrue);
    expect(repository.deletedIds, <String>['s1']);
  });

  test('watch list of songs returns the same listenable every time', () {
    final WatchListOfSongsUseCase watchSongs = WatchListOfSongsUseCase(repository);

    expect(identical(watchSongs(), watchSongs()), isTrue);
  });
}
