import 'package:hive_ce/hive_ce.dart';

import '../../../../core/data/data_sources/local_storage_service.dart';
import '../models/usage_history_model.dart';

/// The history in two Hive boxes: id → ISO time of the last opening or playback.
final class HiveHistoryService {
  static const String _songsBoxName = 'opened_songs';
  static const String _coversBoxName = 'played_covers';

  final LocalStorageService _storage;

  Box<dynamic>? _songs;
  Box<dynamic>? _covers;

  /// Creates the service.
  HiveHistoryService({required this._storage});

  /// Opens the boxes; returns this for `registerSingletonAsync`.
  Future<HiveHistoryService> init() async {
    _songs = await _storage.openBox(_songsBoxName);
    _covers = await _storage.openBox(_coversBoxName);
    return this;
  }

  /// The stored history.
  UsageHistoryModel read() => UsageHistoryModel.fromMaps(songs: _songs!.toMap(), covers: _covers!.toMap());

  /// Stores that [songId] was opened at [time].
  Future<void> putSongOpened(String songId, DateTime time) => _songs!.put(songId, UsageHistoryModel.encodeTime(time));

  /// Forgets the opening of [songId].
  Future<void> deleteSong(String songId) => _songs!.delete(songId);

  /// Forgets the whole history.
  Future<void> clear() async {
    await _songs!.clear();
    await _covers!.clear();
  }

  /// Stores that [recordingId] was played at [time].
  Future<void> putCoverPlayed(String recordingId, DateTime time) =>
      _covers!.put(recordingId, UsageHistoryModel.encodeTime(time));
}
