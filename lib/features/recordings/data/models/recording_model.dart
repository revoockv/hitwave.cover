import '../../domain/entities/recording.dart';
import '../../domain/entities/recording_status.dart';
import '../../domain/entities/enhance_failure.dart';

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
  static const String _failureField = 'enhanceFailure';

  /// The field of the app versions before 2.0, a Ukrainian text; only read.
  static const String _legacyErrorField = 'enhanceError';

  /// The legacy text of an interrupted enhancement.
  static const String _legacyInterruptedError = 'Покращення перервалося — запустіть його ще раз';
  static const String _trimSilenceField = 'trimSilence';
  static const String _silentField = 'silent';
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

  /// Name of the [EnhanceFailure] when the enhancement failed.
  final String? enhanceFailure;

  /// Whether the silence around the singing is cut from the enhanced file.
  final bool trimSilence;

  /// Whether the microphone gave no sound during the whole take.
  final bool isSilent;

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
    required this.enhanceFailure,
    required this.trimSilence,
    this.isSilent = false,
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
      enhanceFailure: map[_failureField] as String? ?? _legacyFailure(map[_legacyErrorField] as String?),
      trimSilence: map[_trimSilenceField] as bool? ?? false,
      isSilent: map[_silentField] as bool? ?? false,
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
      enhanceFailure: entity.enhanceFailure?.name,
      trimSilence: trimSilence,
      isSilent: entity.isSilent,
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
      _failureField: enhanceFailure,
      _trimSilenceField: trimSilence,
      _silentField: isSilent,
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
      enhanceFailure: EnhanceFailure.values.asNameMap()[enhanceFailure],
      isSilent: isSilent,
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
    String? enhanceFailure,
    bool clearEnhanceFailure = false,
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
      enhanceFailure: clearEnhanceFailure ? null : enhanceFailure ?? this.enhanceFailure,
      trimSilence: trimSilence ?? this.trimSilence,
      isSilent: isSilent,
    );
  }

  static String _fileName(String path) => path.split(_separator).last;

  /// The failure of a legacy [error] text: the interrupted one or any other.
  static String? _legacyFailure(String? error) => switch (error) {
    null => null,
    _legacyInterruptedError => EnhanceFailure.interrupted.name,
    _ => EnhanceFailure.failed.name,
  };
}
