/// When the songs were last opened and the covers last played on this device.
final class UsageHistory {
  /// No history yet.
  static const UsageHistory empty = UsageHistory(
    songsOpenedAt: <String, DateTime>{},
    coversPlayedAt: <String, DateTime>{},
  );

  /// Last opening of every opened song, by song id.
  final Map<String, DateTime> songsOpenedAt;

  /// Last playback of every played cover, by recording id.
  final Map<String, DateTime> coversPlayedAt;

  /// Creates a [UsageHistory].
  const UsageHistory({required this.songsOpenedAt, required this.coversPlayedAt});
}
