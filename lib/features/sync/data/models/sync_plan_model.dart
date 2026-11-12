import '../../../song/domain/entities/song.dart';
import 'sync_snapshot_model.dart';
import 'sync_song_key_model.dart';

/// What the user decided that the hosting device must do before it merges: delete, update and
/// forget deletions of songs and covers.
final class SyncPlanModel {
  static const String _deleteSongsField = 'deleteSongs';
  static const String _forgetSongsField = 'forgetSongs';
  static const String _updateSongsField = 'updateSongs';
  static const String _deleteCoversField = 'deleteCovers';
  static const String _forgetCoversField = 'forgetCovers';

  /// Songs to delete there.
  final List<SyncSongKeyModel> deleteSongs;

  /// Songs whose deletion is forgotten there (they come back with this snapshot).
  final List<SyncSongKeyModel> forgetSongs;

  /// Songs whose lyrics, album, speed and space above the lyrics are taken there.
  final List<Song> updateSongs;

  /// Covers to delete there.
  final List<String> deleteCovers;

  /// Covers whose deletion is forgotten there (they come back with this exchange).
  final List<String> forgetCovers;

  /// Creates a [SyncPlanModel].
  const SyncPlanModel({
    required this.deleteSongs,
    required this.forgetSongs,
    required this.updateSongs,
    required this.deleteCovers,
    required this.forgetCovers,
  });

  /// Nothing to do.
  static const SyncPlanModel empty = SyncPlanModel(
    deleteSongs: <SyncSongKeyModel>[],
    forgetSongs: <SyncSongKeyModel>[],
    updateSongs: <Song>[],
    deleteCovers: <String>[],
    forgetCovers: <String>[],
  );

  /// Reads the JSON of the other device.
  factory SyncPlanModel.fromJson(Map<String, dynamic> json) => SyncPlanModel(
    deleteSongs: _keys(json[_deleteSongsField]),
    forgetSongs: _keys(json[_forgetSongsField]),
    updateSongs: <Song>[
      for (final dynamic song in json[_updateSongsField] as List<dynamic>? ?? const <dynamic>[])
        SyncSnapshotModel.songFromJson(song as Map<String, dynamic>),
    ],
    deleteCovers: (json[_deleteCoversField] as List<dynamic>? ?? const <dynamic>[]).cast<String>(),
    forgetCovers: (json[_forgetCoversField] as List<dynamic>? ?? const <dynamic>[]).cast<String>(),
  );

  /// The JSON to send.
  Map<String, dynamic> toJson() => <String, dynamic>{
    _deleteSongsField: <Map<String, dynamic>>[for (final SyncSongKeyModel song in deleteSongs) song.toJson()],
    _forgetSongsField: <Map<String, dynamic>>[for (final SyncSongKeyModel song in forgetSongs) song.toJson()],
    _updateSongsField: <Map<String, dynamic>>[for (final Song song in updateSongs) SyncSnapshotModel.songToJson(song)],
    _deleteCoversField: deleteCovers,
    _forgetCoversField: forgetCovers,
  };

  static List<SyncSongKeyModel> _keys(Object? json) => <SyncSongKeyModel>[
    for (final dynamic song in json as List<dynamic>? ?? const <dynamic>[])
      SyncSongKeyModel.fromJson(song as Map<String, dynamic>),
  ];
}
