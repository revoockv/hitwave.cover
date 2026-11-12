import 'package:hive_ce/hive_ce.dart';

import '../../../../core/data/data_sources/local_storage_service.dart';
import '../models/sync_song_key_model.dart';

/// What was deleted on this device, so a synchronisation can tell "deleted here" from "never
/// was here": songs by artist and name, covers by id.
final class HiveSyncTombstoneService {
  static const String _defaultBoxName = 'sync_tombstones';
  static const String _songPrefix = 'song:';
  static const String _coverPrefix = 'cover:';
  static const String _coverValue = '';

  final LocalStorageService _storage;
  final String _boxName;

  Box<dynamic>? _box;

  /// Creates the service; [boxName] is replaced in tests that run two devices in one process.
  HiveSyncTombstoneService({required this._storage, this._boxName = _defaultBoxName});

  /// Opens the box; returns this for `registerSingletonAsync`.
  Future<HiveSyncTombstoneService> init() async {
    _box = await _storage.openBox(_boxName);
    return this;
  }

  Box<dynamic> get _tombstones => _box!;

  /// The deleted songs.
  List<SyncSongKeyModel> deletedSongs() => <SyncSongKeyModel>[
    for (final MapEntry<dynamic, dynamic> entry in _tombstones.toMap().entries)
      if (entry.key is String && (entry.key as String).startsWith(_songPrefix))
        SyncSongKeyModel.fromJson(entry.value as Map<dynamic, dynamic>),
  ];

  /// Ids of the deleted covers.
  Set<String> deletedCovers() => <String>{
    for (final dynamic key in _tombstones.keys)
      if (key is String && key.startsWith(_coverPrefix)) key.substring(_coverPrefix.length),
  };

  /// Remembers that the song [song] was deleted.
  Future<void> putSong(SyncSongKeyModel song) => _tombstones.put('$_songPrefix${song.key}', song.toJson());

  /// Forgets the deletion of [song] (it is back).
  Future<void> forgetSong(SyncSongKeyModel song) => _tombstones.delete('$_songPrefix${song.key}');

  /// Remembers that the cover [id] was deleted.
  Future<void> putCover(String id) => _tombstones.put('$_coverPrefix$id', _coverValue);

  /// Forgets the deletion of the cover [id] (it is back).
  Future<void> forgetCover(String id) => _tombstones.delete('$_coverPrefix$id');
}
