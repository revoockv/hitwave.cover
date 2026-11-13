import '../../domain/entities/recording_preferences.dart';

/// The recording options as stored in Hive.
final class RecordingPreferencesModel {
  static const String _recordField = 'record';
  static const String _trimSilenceField = 'trimSilence';

  /// Whether pressing start also records a take.
  final bool record;

  /// Whether the silence around the singing is cut.
  final bool trimSilence;

  /// Creates a [RecordingPreferencesModel].
  const RecordingPreferencesModel({required this.record, required this.trimSilence});

  /// Reads a stored map; a missing field keeps its first-start value.
  factory RecordingPreferencesModel.fromMap(Map<dynamic, dynamic> map) => RecordingPreferencesModel(
    record: map[_recordField] as bool? ?? RecordingPreferences.initial.record,
    trimSilence: map[_trimSilenceField] as bool? ?? RecordingPreferences.initial.trimSilence,
  );

  /// The model of [preferences].
  factory RecordingPreferencesModel.fromEntity(RecordingPreferences preferences) =>
      RecordingPreferencesModel(record: preferences.record, trimSilence: preferences.trimSilence);

  /// The map to store.
  Map<String, dynamic> toMap() => <String, dynamic>{_recordField: record, _trimSilenceField: trimSilence};

  /// The domain entity.
  RecordingPreferences toEntity() => RecordingPreferences(record: record, trimSilence: trimSilence);
}
