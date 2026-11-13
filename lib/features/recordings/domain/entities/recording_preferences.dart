/// The recording options of the lyrics page, remembered between visits and app starts.
final class RecordingPreferences {
  /// The options of a first start: no recording, silence trimmed.
  static const RecordingPreferences initial = RecordingPreferences(record: false, trimSilence: true);

  /// Whether pressing start also records a take.
  final bool record;

  /// Whether the silence before and after the singing is cut from the enhanced take.
  final bool trimSilence;

  /// The chosen sound input, or `null` for the system one.
  final String? microphoneId;

  /// Name of the chosen sound input, or `null` for the system one.
  final String? microphoneLabel;

  /// Creates [RecordingPreferences].
  const RecordingPreferences({
    required this.record,
    required this.trimSilence,
    this.microphoneId,
    this.microphoneLabel,
  });

  /// A copy with the checkboxes changed; the microphone stays.
  RecordingPreferences copyWith({bool? record, bool? trimSilence}) => RecordingPreferences(
    record: record ?? this.record,
    trimSilence: trimSilence ?? this.trimSilence,
    microphoneId: microphoneId,
    microphoneLabel: microphoneLabel,
  );

  /// A copy recording from [id] named [label]; `null` for the system input.
  RecordingPreferences withMicrophone({required String? id, required String? label}) =>
      RecordingPreferences(record: record, trimSilence: trimSilence, microphoneId: id, microphoneLabel: label);
}
