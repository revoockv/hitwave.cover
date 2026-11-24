import '../../domain/entities/recording_preferences.dart';

/// The recording options as stored in Hive.
final class RecordingPreferencesModel {
  static const String _recordField = 'record';
  static const String _trimSilenceField = 'trimSilence';
  static const String _microphoneIdField = 'microphoneId';
  static const String _microphoneLabelField = 'microphoneLabel';

  /// Whether pressing start also records a take.
  final bool record;

  /// Whether the silence around the singing is cut.
  final bool trimSilence;

  /// The chosen sound input, or `null` for the system one.
  final String? microphoneId;

  /// Name of the chosen sound input.
  final String? microphoneLabel;

  /// Creates a [RecordingPreferencesModel].
  const RecordingPreferencesModel({
    required this.record,
    required this.trimSilence,
    this.microphoneId,
    this.microphoneLabel,
  });

  /// Reads what Hive returned: `null` when nothing (or no map) was stored.
  static RecordingPreferencesModel? fromStored(Object? value) =>
      value is Map<dynamic, dynamic> ? RecordingPreferencesModel.fromMap(value) : null;

  /// Reads a stored map; a missing field keeps its first-start value.
  factory RecordingPreferencesModel.fromMap(Map<dynamic, dynamic> map) => RecordingPreferencesModel(
    record: map[_recordField] as bool? ?? RecordingPreferences.initial.record,
    trimSilence: map[_trimSilenceField] as bool? ?? RecordingPreferences.initial.trimSilence,
    microphoneId: map[_microphoneIdField] as String?,
    microphoneLabel: map[_microphoneLabelField] as String?,
  );

  /// The model of [preferences].
  factory RecordingPreferencesModel.fromEntity(RecordingPreferences preferences) => RecordingPreferencesModel(
    record: preferences.record,
    trimSilence: preferences.trimSilence,
    microphoneId: preferences.microphoneId,
    microphoneLabel: preferences.microphoneLabel,
  );

  /// The map to store.
  Map<String, dynamic> toMap() => <String, dynamic>{
    _recordField: record,
    _trimSilenceField: trimSilence,
    _microphoneIdField: microphoneId,
    _microphoneLabelField: microphoneLabel,
  };

  /// The domain entity.
  RecordingPreferences toEntity() => RecordingPreferences(
    record: record,
    trimSilence: trimSilence,
    microphoneId: microphoneId,
    microphoneLabel: microphoneLabel,
  );
}
