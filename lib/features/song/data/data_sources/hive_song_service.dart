import 'dart:async';

import 'package:hive_ce/hive_ce.dart';

import '../../../../core/data/data_sources/local_storage_service.dart';
import '../models/cover_model.dart';
import '../models/song_model.dart';
import 'song_data_source.dart';

/// The songs kept on this device in Hive CE, used without an account.
///
/// Each song is one map in the songs box, keyed by its id, with its covers
/// inside. A second box remembers whether the user refused to move these songs
/// into an account; any change of the songs asks again.
final class HiveSongService implements SongDataSource {
  static const String _songsBoxName = 'songs';
  static const String _settingsBoxName = 'song_settings';
  static const String _transferDeclinedKey = 'transferDeclined';
  static const String _idField = 'id';
  static const String _authorField = 'author';
  static const String _nameField = 'name';
  static const String _albumField = 'album';
  static const String _lyricsField = 'lyrics';
  static const String _scrollSpeedField = 'scrollSpeed';
  static const String _leadInField = 'leadIn';
  static const String _coversField = 'covers';
  static const String _timestampField = 'timestamp';
  static const String _notesField = 'notes';
  static const String _songIdPrefix = 's';
  static const String _coverIdPrefix = 'c';

  final LocalStorageService _storage;

  Box<dynamic>? _songsBox;

  Box<dynamic>? _settingsBox;

  int _idCounter = 0;

  /// Creates a new [HiveSongService].
  HiveSongService({required this._storage});

  /// Opens the boxes; returns this for `registerSingletonAsync`.
  Future<HiveSongService> init() async {
    _songsBox = await _storage.openBox(_songsBoxName);
    _settingsBox = await _storage.openBox(_settingsBoxName);
    return this;
  }

  Box<dynamic> get _songs => _songsBox!;

  Box<dynamic> get _settings => _settingsBox!;

  /// Number of songs on the device.
  int get songCount => _songs.length;

  /// Whether the user refused to move the songs on the device into the account.
  bool get isTransferDeclined => _settings.get(_transferDeclinedKey, defaultValue: false) as bool;

  /// Saves whether the user refused to move the songs into the account.
  Future<void> setTransferDeclined(bool isDeclined) => _settings.put(_transferDeclinedKey, isDeclined);

  /// The songs on the device sorted by name.
  List<SongModel> readSongs() {
    final List<SongModel> songs = _songs.values.map(_songMap).map(_toSongModel).toList()..sort(_byName);
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
    final Map<String, dynamic>? song = _readSong(songId);
    if (song == null) return const <CoverModel>[];
    final List<CoverModel> covers = _coverMaps(song).map(_toCoverModel).toList()..sort(_newestFirst);
    return covers;
  }

  @override
  Future<String> addSong(SongModel song) async {
    final String id = _newId(_songIdPrefix);
    await _writeSong(id, <String, dynamic>{
      _idField: id,
      _authorField: song.author,
      _nameField: song.name,
      _albumField: song.album,
      _lyricsField: song.lyrics,
      _scrollSpeedField: song.scrollSpeed,
      _leadInField: song.leadIn,
      _coversField: <Map<String, dynamic>>[],
    });
    return id;
  }

  @override
  Future<void> updateSong(SongModel song) => _updateFields(song.id, <String, dynamic>{
    _authorField: song.author,
    _nameField: song.name,
    _albumField: song.album,
    _lyricsField: song.lyrics,
  });

  @override
  Future<void> updateSongScrollSpeed({required String songId, required double speed}) =>
      _updateFields(songId, <String, dynamic>{_scrollSpeedField: speed});

  @override
  Future<void> updateSongLeadIn({required String songId, required double leadIn}) =>
      _updateFields(songId, <String, dynamic>{_leadInField: leadIn});

  @override
  Future<void> updateSongLyrics({required String songId, required String lyrics}) =>
      _updateFields(songId, <String, dynamic>{_lyricsField: lyrics});

  @override
  Future<void> deleteSong(String songId) async {
    await _songs.delete(songId);
    await setTransferDeclined(false);
  }

  @override
  Future<String> addCover({required String songId, required CoverModel cover}) async {
    final String id = _newId(_coverIdPrefix);
    final Map<String, dynamic> song = _requireSong(songId);
    final List<Map<String, dynamic>> covers = _coverMaps(song)
      ..add(<String, dynamic>{_idField: id, _timestampField: cover.timestamp, _notesField: cover.notes});
    await _writeSong(songId, song..[_coversField] = covers);
    return id;
  }

  @override
  Future<void> updateCover({required String songId, required CoverModel cover}) async {
    final Map<String, dynamic> song = _requireSong(songId);
    final List<Map<String, dynamic>> covers = _coverMaps(song);
    for (final Map<String, dynamic> stored in covers) {
      if (stored[_idField] != cover.id) continue;
      stored[_timestampField] = cover.timestamp;
      stored[_notesField] = cover.notes;
    }
    await _writeSong(songId, song..[_coversField] = covers);
  }

  @override
  Future<void> deleteCover({required String songId, required String coverId}) async {
    final Map<String, dynamic> song = _requireSong(songId);
    final List<Map<String, dynamic>> covers = _coverMaps(song)
      ..removeWhere((Map<String, dynamic> cover) => cover[_idField] == coverId);
    await _writeSong(songId, song..[_coversField] = covers);
  }

  Future<void> _updateFields(String songId, Map<String, dynamic> fields) async {
    final Map<String, dynamic> song = _requireSong(songId)..addAll(fields);
    await _writeSong(songId, song);
  }

  Future<void> _writeSong(String songId, Map<String, dynamic> song) async {
    await _songs.put(songId, song);
    await setTransferDeclined(false);
  }

  Map<String, dynamic>? _readSong(String songId) {
    final Object? stored = _songs.get(songId);
    return stored == null ? null : _songMap(stored);
  }

  Map<String, dynamic> _requireSong(String songId) {
    final Map<String, dynamic>? song = _readSong(songId);
    if (song == null) throw StateError(songId);
    return song;
  }

  String _newId(String prefix) => '$prefix${DateTime.now().microsecondsSinceEpoch}${_idCounter++}';

  static Map<String, dynamic> _songMap(Object? stored) => Map<String, dynamic>.from(stored! as Map<dynamic, dynamic>);

  static List<Map<String, dynamic>> _coverMaps(Map<String, dynamic> song) {
    final List<dynamic> covers = song[_coversField] as List<dynamic>? ?? const <dynamic>[];
    return covers.map(_songMap).toList();
  }

  static SongModel _toSongModel(Map<String, dynamic> song) {
    return SongModel(
      id: song[_idField] as String,
      author: song[_authorField] as String,
      name: song[_nameField] as String,
      album: song[_albumField] as String?,
      lyrics: song[_lyricsField] as String,
      coverIds: _coverMaps(song).map(_coverId).toList(),
      scrollSpeed: (song[_scrollSpeedField] as num?)?.toDouble(),
      leadIn: (song[_leadInField] as num?)?.toDouble(),
    );
  }

  static CoverModel _toCoverModel(Map<String, dynamic> cover) {
    return CoverModel(
      id: cover[_idField] as String,
      timestamp: cover[_timestampField] as int,
      audioBytes: const <int>[],
      notes: cover[_notesField] as String?,
    );
  }

  static String _coverId(Map<String, dynamic> cover) => cover[_idField] as String;

  static int _byName(SongModel a, SongModel b) => a.name.compareTo(b.name);

  static int _newestFirst(CoverModel a, CoverModel b) => b.timestamp.compareTo(a.timestamp);
}
