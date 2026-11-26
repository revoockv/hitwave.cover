/// The start options of the lyrics page (record a take, trim its silence, count it as practice), remembered between
/// visits and app starts.
final class RecordingPreferences {
  /// The options of a first start: no recording, silence trimmed, counted as practice.
  static const RecordingPreferences initial = RecordingPreferences(record: false, trimSilence: true);

  /// Whether pressing start also records a take.
  final bool record;

  /// Whether the silence before and after the singing is cut from the enhanced take.
  final bool trimSilence;

  /// Whether the time from start to stop is counted as practice; off, the lyrics only scroll (or a take is only
  /// recorded) and the statistics stay as they were.
  final bool countPractice;

  /// The chosen sound input, or `null` for the system one.
  final String? microphoneId;

  /// Name of the chosen sound input, or `null` for the system one.
  final String? microphoneLabel;

  /// Creates [RecordingPreferences].
  const RecordingPreferences({
    required this.record,
    required this.trimSilence,
    this.countPractice = true,
    this.microphoneId,
    this.microphoneLabel,
  });

  /// A copy with the checkboxes changed; the microphone stays.
  RecordingPreferences copyWith({bool? record, bool? trimSilence, bool? countPractice}) => RecordingPreferences(
    record: record ?? this.record,
    trimSilence: trimSilence ?? this.trimSilence,
    countPractice: countPractice ?? this.countPractice,
    microphoneId: microphoneId,
    microphoneLabel: microphoneLabel,
  );

  /// A copy recording from [id] named [label]; `null` for the system input.
  RecordingPreferences withMicrophone({required String? id, required String? label}) => RecordingPreferences(
    record: record,
    trimSilence: trimSilence,
    countPractice: countPractice,
    microphoneId: id,
    microphoneLabel: label,
  );
}
