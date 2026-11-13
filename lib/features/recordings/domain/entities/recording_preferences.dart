/// The recording options of the lyrics page, remembered between visits and app starts.
final class RecordingPreferences {
  /// The options of a first start: no recording, silence trimmed.
  static const RecordingPreferences initial = RecordingPreferences(record: false, trimSilence: true);

  /// Whether pressing start also records a take.
  final bool record;

  /// Whether the silence before and after the singing is cut from the enhanced take.
  final bool trimSilence;

  /// Creates [RecordingPreferences].
  const RecordingPreferences({required this.record, required this.trimSilence});

  /// A copy with the given options changed.
  RecordingPreferences copyWith({bool? record, bool? trimSilence}) =>
      RecordingPreferences(record: record ?? this.record, trimSilence: trimSilence ?? this.trimSilence);
}
