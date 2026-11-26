import 'dart:async';

import 'package:hive_ce/hive_ce.dart';

import '../../../../core/data/data_sources/local_storage_service.dart';
import '../../domain/entities/lyrics_layout.dart';
import '../models/cover_model.dart';
import '../models/song_model.dart';
import '../models/song_record_model.dart';
import 'song_data_source.dart';

/// The songs kept on this device in Hive CE.
///
/// Each song is one [SongRecordModel] in the songs box, keyed by its id, with its covers inside.
final class HiveSongService implements SongDataSource {
  static const String _songsBoxName = 'songs';
  static const String _songIdPrefix = 's';
  static const String _coverIdPrefix = 'c';

  final LocalStorageService _storage;

  Box<dynamic>? _songsBox;

  int _idCounter = 0;

  /// Creates a new [HiveSongService].
  HiveSongService({required this._storage});

  /// Opens the boxes; returns this for `registerSingletonAsync`.
  Future<HiveSongService> init() async {
    _songsBox = await _storage.openBox(_songsBoxName);
    return this;
  }

  Box<dynamic> get _songs => _songsBox!;

  /// The songs on the device sorted by name.
  List<SongModel> readSongs() {
    final List<SongModel> songs = _songs.values.map(SongRecordModel.fromStored).map(_toSongModel).toList()
      ..sort(_byName);
    return songs;
  }

  /// Emits the songs now and after every change of the box.
  ///
  /// The box subscription is cancelled without waiting: the future of
  /// cancelling a Hive `watch()` stream never completes, and awaiting it would
  /// block the caller's `cancel()`.
  @override
  Stream<List<SongModel>> watchSongs() {
    StreamSubscription<BoxEvent>? boxSubscription;
    late final StreamController<List<SongModel>> songsController;

    void emitSongs([BoxEvent? _]) => songsController.add(readSongs());

    void startWatching() {
      emitSongs();
      boxSubscription = _songs.watch().listen(emitSongs);
    }

    void stopWatching() {
      unawaited(boxSubscription?.cancel());
      boxSubscription = null;
    }

    songsController = StreamController<List<SongModel>>(onListen: startWatching, onCancel: stopWatching);
    return songsController.stream;
  }

  @override
  Future<List<CoverModel>> getCovers(String songId) async {
    final SongRecordModel? song = _readSong(songId);
    if (song == null) return const <CoverModel>[];
    return List<CoverModel>.of(song.covers)..sort(_newestFirst);
  }

  @override
  Future<String> addSong(SongModel song) async {
    final String id = _newId(_songIdPrefix);
    await _writeSong(SongRecordModel.fromSongModel(song, id: id));
    return id;
  }

  @override
  Future<void> updateSong(SongModel song) => _update(song.id, (SongRecordModel stored) => stored.withDetailsOf(song));

  @override
  Future<void> updateSongScrollSpeed({required String songId, required LyricsLayout layout, required double speed}) =>
      _update(songId, (SongRecordModel stored) => stored.withScrollSpeed(layout, speed));

  @override
  Future<void> updateSongLeadIn({required String songId, required LyricsLayout layout, required double leadIn}) =>
      _update(songId, (SongRecordModel stored) => stored.withLeadIn(layout, leadIn));

  @override
  Future<void> updateSongLyrics({required String songId, required String lyrics}) =>
      _update(songId, (SongRecordModel stored) => stored.withLyrics(lyrics));

  @override
  Future<void> deleteSong(String songId) => _songs.delete(songId);

  @override
  Future<String> addCover({required String songId, required CoverModel cover}) async {
    final String id = _newId(_coverIdPrefix);
    await _update(
      songId,
      (SongRecordModel stored) => stored.withCovers(<CoverModel>[...stored.covers, cover.withId(id)]),
    );
    return id;
  }

  @override
  Future<void> updateCover({required String songId, required CoverModel cover}) => _update(
    songId,
    (SongRecordModel stored) => stored.withCovers(<CoverModel>[
      for (final CoverModel storedCover in stored.covers) storedCover.id == cover.id ? cover : storedCover,
    ]),
  );

  @override
  Future<void> deleteCover({required String songId, required String coverId}) => _update(
    songId,
    (SongRecordModel stored) => stored.withCovers(<CoverModel>[
      for (final CoverModel cover in stored.covers)
        if (cover.id != coverId) cover,
    ]),
  );

  /// Stores the song [songId] as [change] makes it from the stored one; throws when there is none.
  Future<void> _update(String songId, SongRecordModel Function(SongRecordModel stored) change) async {
    final SongRecordModel? stored = _readSong(songId);
    if (stored == null) throw StateError(songId);
    await _writeSong(change(stored));
  }

  Future<void> _writeSong(SongRecordModel song) => _songs.put(song.id, song.toMap());

  SongRecordModel? _readSong(String songId) {
    final Object? stored = _songs.get(songId);
    return stored == null ? null : SongRecordModel.fromStored(stored);
  }

  String _newId(String prefix) => '$prefix${DateTime.now().microsecondsSinceEpoch}${_idCounter++}';

  static SongModel _toSongModel(SongRecordModel song) => song.toSongModel();

  static int _byName(SongModel a, SongModel b) => a.name.compareTo(b.name);

  static int _newestFirst(CoverModel a, CoverModel b) => b.timestamp.compareTo(a.timestamp);
}
