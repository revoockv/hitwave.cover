import '../../domain/entities/recording.dart';
import '../../domain/entities/recording_status.dart';

/// A recording as stored in Hive and in a backup archive.
///
/// [rawFile] and [enhancedFile] are file names inside the recordings folder, not full paths
/// (the app folder moves between updates on iOS); [RecordingModel.toEntity] makes them full.
final class RecordingModel {
  static const String _idField = 'id';
  static const String _songIdField = 'songId';
  static const String _recordedAtField = 'recordedAt';
  static const String _durationField = 'durationSeconds';
  static const String _rawFileField = 'rawFile';
  static const String _enhancedFileField = 'enhancedFile';
  static const String _keptFromField = 'keptFromSeconds';
  static const String _keptToField = 'keptToSeconds';
  static const String _statusField = 'status';
  static const String _errorField = 'enhanceError';
  static const String _trimSilenceField = 'trimSilence';
  static const String _separator = '/';

  /// Unique id.
  final String id;

  /// Id of the song.
  final String songId;

  /// When recording started.
  final DateTime recordedAt;

  /// Length of the raw take in seconds.
  final double durationSeconds;

  /// File name of the raw take.
  final String rawFile;

  /// File name of the enhanced take, once there is one.
  final String? enhancedFile;

  /// Start of the kept part of the raw take, in seconds.
  final double keptFromSeconds;

  /// End of the kept part of the raw take, in seconds; `null` = the end.
  final double? keptToSeconds;

  /// State of the enhancement.
  final RecordingStatus status;

  /// Why the enhancement failed.
  final String? enhanceError;

  /// Whether the silence around the singing is cut from the enhanced file.
  final bool trimSilence;

  /// Creates a [RecordingModel].
  const RecordingModel({
    required this.id,
    required this.songId,
    required this.recordedAt,
    required this.durationSeconds,
    required this.rawFile,
    required this.enhancedFile,
    required this.keptFromSeconds,
    required this.keptToSeconds,
    required this.status,
    required this.enhanceError,
    required this.trimSilence,
  });

  /// Reads a stored map.
  factory RecordingModel.fromMap(Map<dynamic, dynamic> map) {
    return RecordingModel(
      id: map[_idField] as String,
      songId: map[_songIdField] as String,
      recordedAt: DateTime.fromMillisecondsSinceEpoch(map[_recordedAtField] as int),
      durationSeconds: (map[_durationField] as num).toDouble(),
      rawFile: map[_rawFileField] as String,
      enhancedFile: map[_enhancedFileField] as String?,
      keptFromSeconds: (map[_keptFromField] as num?)?.toDouble() ?? 0,
      keptToSeconds: (map[_keptToField] as num?)?.toDouble(),
      status: RecordingStatus.values.byName(map[_statusField] as String),
      enhanceError: map[_errorField] as String?,
      trimSilence: map[_trimSilenceField] as bool? ?? false,
    );
  }

  /// Creates a model from a domain [entity]; the paths become file names.
  factory RecordingModel.fromEntity(Recording entity, {required bool trimSilence}) {
    return RecordingModel(
      id: entity.id,
      songId: entity.songId,
      recordedAt: entity.recordedAt,
      durationSeconds: entity.durationSeconds,
      rawFile: _fileName(entity.rawPath),
      enhancedFile: entity.enhancedPath == null ? null : _fileName(entity.enhancedPath!),
      keptFromSeconds: entity.keptFromSeconds,
      keptToSeconds: entity.keptToSeconds,
      status: entity.status,
      enhanceError: entity.enhanceError,
      trimSilence: trimSilence,
    );
  }

  /// The map to store.
  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      _idField: id,
      _songIdField: songId,
      _recordedAtField: recordedAt.millisecondsSinceEpoch,
      _durationField: durationSeconds,
      _rawFileField: rawFile,
      _enhancedFileField: enhancedFile,
      _keptFromField: keptFromSeconds,
      _keptToField: keptToSeconds,
      _statusField: status.name,
      _errorField: enhanceError,
      _trimSilenceField: trimSilence,
    };
  }

  /// Converts the model into a domain entity with full paths inside [folder].
  Recording toEntity({required String folder}) {
    return Recording(
      id: id,
      songId: songId,
      recordedAt: recordedAt,
      durationSeconds: durationSeconds,
      rawPath: '$folder$_separator$rawFile',
      enhancedPath: enhancedFile == null ? null : '$folder$_separator$enhancedFile',
      keptFromSeconds: keptFromSeconds,
      keptToSeconds: keptToSeconds,
      status: status,
      enhanceError: enhanceError,
    );
  }

  /// A copy with the given fields changed.
  RecordingModel copyWith({
    String? songId,
    double? durationSeconds,
    String? enhancedFile,
    double? keptFromSeconds,
    double? keptToSeconds,
    RecordingStatus? status,
    String? enhanceError,
    bool clearEnhanceError = false,
    bool? trimSilence,
  }) {
    return RecordingModel(
      id: id,
      songId: songId ?? this.songId,
      recordedAt: recordedAt,
      durationSeconds: durationSeconds ?? this.durationSeconds,
      rawFile: rawFile,
      enhancedFile: enhancedFile ?? this.enhancedFile,
      keptFromSeconds: keptFromSeconds ?? this.keptFromSeconds,
      keptToSeconds: keptToSeconds ?? this.keptToSeconds,
      status: status ?? this.status,
      enhanceError: clearEnhanceError ? null : enhanceError ?? this.enhanceError,
      trimSilence: trimSilence ?? this.trimSilence,
    );
  }

  static String _fileName(String path) => path.split(_separator).last;
}
