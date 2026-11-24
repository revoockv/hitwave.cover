import 'package:hive_ce/hive_ce.dart';

import '../../../../core/data/data_sources/local_storage_service.dart';
import '../models/sync_song_key_model.dart';

/// What was deleted on this device, so a synchronisation can tell "deleted here" from "never
/// was here": songs by artist and name, covers by id.
final class HiveSyncTombstoneService {
  static const String _defaultBoxName = 'sync_tombstones';
  static const String _songPrefix = 'song:';
  static const String _coverPrefix = 'cover:';

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
        SyncSongKeyModel.fromStored(entry.value),
  ];

  /// The deleted covers by id, with the time of the deletion when it is known.
  Map<String, DateTime?> deletedCovers() => <String, DateTime?>{
    for (final MapEntry<dynamic, dynamic> entry in _tombstones.toMap().entries)
      if (entry.key is String && (entry.key as String).startsWith(_coverPrefix))
        (entry.key as String).substring(_coverPrefix.length): DateTime.tryParse(
          entry.value as String? ?? '',
        )?.toLocal(),
  };

  /// Remembers that the song [song] was deleted now.
  Future<void> putSong(SyncSongKeyModel song) => _tombstones.put(
    '$_songPrefix${song.key}',
    SyncSongKeyModel(author: song.author, name: song.name, deletedAt: DateTime.now()).toJson(),
  );

  /// Forgets the deletion of [song] (it is back).
  Future<void> forgetSong(SyncSongKeyModel song) => _tombstones.delete('$_songPrefix${song.key}');

  /// Remembers that the cover [id] was deleted now.
  Future<void> putCover(String id) => _tombstones.put('$_coverPrefix$id', DateTime.now().toUtc().toIso8601String());

  /// Forgets the deletion of the cover [id] (it is back).
  Future<void> forgetCover(String id) => _tombstones.delete('$_coverPrefix$id');
}
