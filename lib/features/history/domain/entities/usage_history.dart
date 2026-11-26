/// When one song was last opened or one cover last played.
final class UsageTime {
  /// The id of the song or of the recording.
  final String id;

  /// The time of the last opening or playback.
  final DateTime at;

  /// Creates a [UsageTime].
  const UsageTime({required this.id, required this.at});
}

/// When the songs were last opened and the covers last played on this device.
final class UsageHistory {
  /// No history yet.
  static final UsageHistory empty = UsageHistory();

  /// The last opening of every opened song, one entry per song.
  final List<UsageTime> songsOpened;

  /// The last playback of every played cover, one entry per recording.
  final List<UsageTime> coversPlayed;

  final Map<String, DateTime> _songOpenedAt;
  final Map<String, DateTime> _coverPlayedAt;

  /// Creates a [UsageHistory]; a later entry of the same id replaces an earlier one.
  UsageHistory({this.songsOpened = const <UsageTime>[], this.coversPlayed = const <UsageTime>[]})
    : _songOpenedAt = _byId(songsOpened),
      _coverPlayedAt = _byId(coversPlayed);

  /// When the song [songId] was last opened; `null` when never.
  DateTime? songOpenedAt(String songId) => _songOpenedAt[songId];

  /// When the cover [recordingId] was last played; `null` when never.
  DateTime? coverPlayedAt(String recordingId) => _coverPlayedAt[recordingId];

  /// Whether nothing was opened or played.
  bool get isEmpty => songsOpened.isEmpty && coversPlayed.isEmpty;

  static Map<String, DateTime> _byId(List<UsageTime> times) => <String, DateTime>{
    for (final UsageTime time in times) time.id: time.at,
  };
}
