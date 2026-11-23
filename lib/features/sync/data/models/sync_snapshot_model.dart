import 'dart:convert';

import '../../../history/domain/entities/usage_history.dart';
import '../../../practice/domain/entities/practice_session.dart';
import '../../../recordings/domain/entities/recording.dart';
import '../../../recordings/domain/entities/recording_status.dart';
import '../../../song/domain/entities/cover.dart';
import '../../../song/domain/entities/song.dart';
import 'sync_song_key_model.dart';

/// A recording as another device describes it; its files are fetched separately.
final class SyncRecordingModel {
  static const String _idField = 'id';
  static const String _songIdField = 'songId';
  static const String _recordedAtField = 'recordedAt';
  static const String _durationField = 'durationSeconds';
  static const String _keptFromField = 'keptFromSeconds';
  static const String _keptToField = 'keptToSeconds';
  static const String _hasEnhancedField = 'hasEnhanced';
  static const String _rawSuffix = '_raw.wav';
  static const String _enhancedSuffix = '_enhanced.wav';

  /// Id of the recording (the same on every device).
  final String id;

  /// Id of its song on the device that sent it.
  final String songId;

  /// When it was recorded.
  final DateTime recordedAt;

  /// Length of the raw take in seconds.
  final double durationSeconds;

  /// Start of the kept part in seconds.
  final double keptFromSeconds;

  /// End of the kept part in seconds, or `null` for the end.
  final double? keptToSeconds;

  /// Whether there is an enhanced file.
  final bool hasEnhanced;

  /// Creates a [SyncRecordingModel].
  const SyncRecordingModel({
    required this.id,
    required this.songId,
    required this.recordedAt,
    required this.durationSeconds,
    required this.keptFromSeconds,
    required this.keptToSeconds,
    required this.hasEnhanced,
  });

  /// The model of [recording].
  factory SyncRecordingModel.fromEntity(Recording recording) => SyncRecordingModel(
    id: recording.id,
    songId: recording.songId,
    recordedAt: recording.recordedAt,
    durationSeconds: recording.durationSeconds,
    keptFromSeconds: recording.keptFromSeconds,
    keptToSeconds: recording.keptToSeconds,
    hasEnhanced: recording.status == RecordingStatus.enhanced && recording.enhancedPath != null,
  );

  /// Reads the JSON of another device.
  factory SyncRecordingModel.fromJson(Map<String, dynamic> json) => SyncRecordingModel(
    id: json[_idField] as String,
    songId: json[_songIdField] as String,
    recordedAt: DateTime.parse(json[_recordedAtField] as String).toLocal(),
    durationSeconds: (json[_durationField] as num).toDouble(),
    keptFromSeconds: (json[_keptFromField] as num).toDouble(),
    keptToSeconds: (json[_keptToField] as num?)?.toDouble(),
    hasEnhanced: json[_hasEnhancedField] as bool,
  );

  /// The JSON to send.
  Map<String, dynamic> toJson() => <String, dynamic>{
    _idField: id,
    _songIdField: songId,
    _recordedAtField: recordedAt.toUtc().toIso8601String(),
    _durationField: durationSeconds,
    _keptFromField: keptFromSeconds,
    _keptToField: keptToSeconds,
    _hasEnhancedField: hasEnhanced,
  };

  /// Name of the raw file in transfers.
  String get rawFile => fileName(id, enhanced: false);

  /// Name of the enhanced file in transfers.
  String get enhancedFile => fileName(id, enhanced: true);

  /// Name of a file of the recording [id] in transfers.
  static String fileName(String id, {required bool enhanced}) => '$id${enhanced ? _enhancedSuffix : _rawSuffix}';
}

/// Everything one device sends to the other: songs, recordings (without files), practice
/// sessions, history and what was deleted on it.
final class SyncSnapshotModel {
  static const String _songsField = 'songs';
  static const String _recordingsField = 'recordings';
  static const String _sessionsField = 'sessions';
  static const String _songsOpenedField = 'songsOpenedAt';
  static const String _coversPlayedField = 'coversPlayedAt';
  static const String _deletedSongsField = 'deletedSongs';
  static const String _deletedCoversField = 'deletedCovers';
  static const String _idField = 'id';
  static const String _authorField = 'author';
  static const String _nameField = 'name';
  static const String _albumField = 'album';
  static const String _lyricsField = 'lyrics';
  static const String _scrollSpeedField = 'scrollSpeed';
  static const String _leadInField = 'leadIn';
  static const String _wideScrollSpeedField = 'wideScrollSpeed';
  static const String _wideLeadInField = 'wideLeadIn';
  static const String _songIdField = 'songId';
  static const String _startedAtField = 'startedAt';
  static const String _secondsField = 'seconds';
  static const String _newSongId = '';

  /// The songs.
  final List<Song> songs;

  /// The recordings.
  final List<SyncRecordingModel> recordings;

  /// The practice sessions.
  final List<PracticeSession> sessions;

  /// The history.
  final UsageHistory history;

  /// The songs deleted on the device.
  final List<SyncSongKeyModel> deletedSongs;

  /// The covers deleted on the device by id, with the time when it is known.
  final Map<String, DateTime?> deletedCovers;

  /// Creates a [SyncSnapshotModel].
  const SyncSnapshotModel({
    required this.songs,
    required this.recordings,
    required this.sessions,
    required this.history,
    required this.deletedSongs,
    required this.deletedCovers,
  });

  /// Reads the JSON text of another device.
  factory SyncSnapshotModel.fromJsonText(String text) =>
      SyncSnapshotModel.fromJson(jsonDecode(text) as Map<String, dynamic>);

  /// Reads the JSON of another device.
  factory SyncSnapshotModel.fromJson(Map<String, dynamic> json) => SyncSnapshotModel(
    songs: <Song>[
      for (final dynamic song in json[_songsField] as List<dynamic>) songFromJson(song as Map<String, dynamic>),
    ],
    recordings: <SyncRecordingModel>[
      for (final dynamic recording in json[_recordingsField] as List<dynamic>)
        SyncRecordingModel.fromJson(recording as Map<String, dynamic>),
    ],
    sessions: <PracticeSession>[
      for (final dynamic session in json[_sessionsField] as List<dynamic>) _session(session as Map<String, dynamic>),
    ],
    history: UsageHistory(
      songsOpenedAt: _times(json[_songsOpenedField] as Map<String, dynamic>),
      coversPlayedAt: _times(json[_coversPlayedField] as Map<String, dynamic>),
    ),
    deletedSongs: <SyncSongKeyModel>[
      for (final dynamic song in json[_deletedSongsField] as List<dynamic>? ?? const <dynamic>[])
        SyncSongKeyModel.fromJson(song as Map<String, dynamic>),
    ],
    deletedCovers: <String, DateTime?>{
      for (final MapEntry<String, dynamic> entry
          in (json[_deletedCoversField] as Map<String, dynamic>? ?? const <String, dynamic>{}).entries)
        entry.key: DateTime.tryParse(entry.value as String? ?? '')?.toLocal(),
    },
  );

  /// The JSON text to send.
  String toJsonText() => jsonEncode(toJson());

  /// The JSON to send.
  Map<String, dynamic> toJson() => <String, dynamic>{
    _songsField: <Map<String, dynamic>>[for (final Song song in songs) songToJson(song)],
    _recordingsField: <Map<String, dynamic>>[for (final SyncRecordingModel recording in recordings) recording.toJson()],
    _sessionsField: <Map<String, dynamic>>[
      for (final PracticeSession session in sessions)
        <String, dynamic>{
          _idField: session.id,
          _songIdField: session.songId,
          _startedAtField: session.startedAt.toUtc().toIso8601String(),
          _secondsField: session.duration.inSeconds,
        },
    ],
    _songsOpenedField: _encodeTimes(history.songsOpenedAt),
    _coversPlayedField: _encodeTimes(history.coversPlayedAt),
    _deletedSongsField: <Map<String, dynamic>>[for (final SyncSongKeyModel song in deletedSongs) song.toJson()],
    _deletedCoversField: <String, String?>{
      for (final MapEntry<String, DateTime?> entry in deletedCovers.entries)
        entry.key: entry.value?.toUtc().toIso8601String(),
    },
  };

  /// The JSON of [song].
  static Map<String, dynamic> songToJson(Song song) => <String, dynamic>{
    _idField: song.id,
    _authorField: song.author,
    _nameField: song.name,
    _albumField: song.album,
    _lyricsField: song.lyrics,
    _scrollSpeedField: song.scrollSpeed,
    _leadInField: song.leadIn,
    _wideScrollSpeedField: song.wideScrollSpeed,
    _wideLeadInField: song.wideLeadIn,
  };

  /// A song of another device; it keeps its id there only to match its recordings and is added
  /// here with a new one.
  static Song songFromJson(Map<String, dynamic> json) => Song(
    id: json[_idField] as String? ?? _newSongId,
    author: json[_authorField] as String,
    name: json[_nameField] as String,
    album: json[_albumField] as String?,
    lyrics: json[_lyricsField] as String,
    covers: const <Cover>[],
    scrollSpeed: (json[_scrollSpeedField] as num?)?.toDouble(),
    leadIn: (json[_leadInField] as num?)?.toDouble(),
    wideScrollSpeed: (json[_wideScrollSpeedField] as num?)?.toDouble(),
    wideLeadIn: (json[_wideLeadInField] as num?)?.toDouble(),
  );

  static PracticeSession _session(Map<String, dynamic> json) => PracticeSession(
    id: json[_idField] as String,
    songId: json[_songIdField] as String,
    startedAt: DateTime.parse(json[_startedAtField] as String).toLocal(),
    duration: Duration(seconds: json[_secondsField] as int),
  );

  static Map<String, DateTime> _times(Map<String, dynamic> json) => <String, DateTime>{
    for (final MapEntry<String, dynamic> entry in json.entries)
      entry.key: DateTime.parse(entry.value as String).toLocal(),
  };

  static Map<String, String> _encodeTimes(Map<String, DateTime> times) => <String, String>{
    for (final MapEntry<String, DateTime> entry in times.entries) entry.key: entry.value.toUtc().toIso8601String(),
  };
}
