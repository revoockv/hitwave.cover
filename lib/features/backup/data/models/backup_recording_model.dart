import '../../../recordings/domain/entities/imported_recording.dart';
import '../../../recordings/domain/entities/recording.dart';

/// A recording inside a ZIP backup: its data and the names of its files in the archive.
final class BackupRecordingModel {
  static const String _songIdField = 'songId';
  static const String _recordedAtField = 'recordedAt';
  static const String _durationField = 'durationSeconds';
  static const String _keptFromField = 'keptFromSeconds';
  static const String _keptToField = 'keptToSeconds';
  static const String _rawFileField = 'rawFile';
  static const String _enhancedFileField = 'enhancedFile';
  static const String _folder = 'recordings/';
  static const String _rawSuffix = '_raw.wav';
  static const String _enhancedSuffix = '_enhanced.wav';
  static const String _separator = '/';

  /// Id of the song in the backup (not on the device that imports it).
  final String songId;

  /// When it was recorded.
  final DateTime recordedAt;

  /// Length of the raw take in seconds.
  final double durationSeconds;

  /// Start of the part the enhanced file covers, in seconds.
  final double keptFromSeconds;

  /// End of that part, in seconds; `null` = the end of the take.
  final double? keptToSeconds;

  /// Name of the raw take in the archive.
  final String rawFile;

  /// Name of the enhanced take in the archive, if there is one.
  final String? enhancedFile;

  /// Creates a [BackupRecordingModel].
  const BackupRecordingModel({
    required this.songId,
    required this.recordedAt,
    required this.durationSeconds,
    required this.keptFromSeconds,
    required this.keptToSeconds,
    required this.rawFile,
    required this.enhancedFile,
  });

  /// The model of [entity], with archive names made from its id.
  factory BackupRecordingModel.fromEntity(Recording entity) {
    return BackupRecordingModel(
      songId: entity.songId,
      recordedAt: entity.recordedAt,
      durationSeconds: entity.durationSeconds,
      keptFromSeconds: entity.keptFromSeconds,
      keptToSeconds: entity.keptToSeconds,
      rawFile: '$_folder${entity.id}$_rawSuffix',
      enhancedFile: entity.enhancedPath == null ? null : '$_folder${entity.id}$_enhancedSuffix',
    );
  }

  /// Reads a map of the `recordings` list.
  factory BackupRecordingModel.fromJson(Object? value) {
    final Map<dynamic, dynamic> json = value! as Map<dynamic, dynamic>;
    return BackupRecordingModel(
      songId: json[_songIdField] as String,
      recordedAt: DateTime.parse(json[_recordedAtField] as String),
      durationSeconds: (json[_durationField] as num).toDouble(),
      keptFromSeconds: (json[_keptFromField] as num?)?.toDouble() ?? 0,
      keptToSeconds: (json[_keptToField] as num?)?.toDouble(),
      rawFile: json[_rawFileField] as String,
      enhancedFile: json[_enhancedFileField] as String?,
    );
  }

  /// The map of the `recordings` list.
  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      _songIdField: songId,
      _recordedAtField: recordedAt.toIso8601String(),
      _durationField: durationSeconds,
      _keptFromField: keptFromSeconds,
      _keptToField: keptToSeconds,
      _rawFileField: rawFile,
      _enhancedFileField: enhancedFile,
    };
  }

  /// The recording to import for the song [songId] of this device, with its files extracted
  /// into [folder].
  ImportedRecording toEntity({required String songId, required String folder}) {
    final String? enhanced = enhancedFile;
    return ImportedRecording(
      songId: songId,
      recordedAt: recordedAt,
      durationSeconds: durationSeconds,
      rawFilePath: '$folder$_separator$rawFile',
      enhancedFilePath: enhanced == null ? null : '$folder$_separator$enhanced',
      keptFromSeconds: keptFromSeconds,
      keptToSeconds: keptToSeconds,
    );
  }
}
