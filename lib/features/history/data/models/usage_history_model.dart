import '../../domain/entities/usage_history.dart';

/// The history as stored in Hive: id → ISO time, one box for the songs and one for the covers.
final class UsageHistoryModel {
  /// Last opening of every song, by song id.
  final Map<String, DateTime> songsOpenedAt;

  /// Last playback of every cover, by recording id.
  final Map<String, DateTime> coversPlayedAt;

  /// Creates a [UsageHistoryModel].
  const UsageHistoryModel({required this.songsOpenedAt, required this.coversPlayedAt});

  /// Reads the stored maps; entries that are no times are skipped.
  factory UsageHistoryModel.fromMaps({required Map<dynamic, dynamic> songs, required Map<dynamic, dynamic> covers}) =>
      UsageHistoryModel(songsOpenedAt: _times(songs), coversPlayedAt: _times(covers));

  /// The stored form of [time].
  static String encodeTime(DateTime time) => time.toUtc().toIso8601String();

  /// The domain entity.
  UsageHistory toEntity() => UsageHistory(
    songsOpenedAt: Map<String, DateTime>.unmodifiable(songsOpenedAt),
    coversPlayedAt: Map<String, DateTime>.unmodifiable(coversPlayedAt),
  );

  static Map<String, DateTime> _times(Map<dynamic, dynamic> map) {
    final Map<String, DateTime> times = <String, DateTime>{};
    for (final MapEntry<dynamic, dynamic> entry in map.entries) {
      final Object? key = entry.key;
      final Object? value = entry.value;
      final DateTime? time = value is String ? DateTime.tryParse(value) : null;
      if (key is String && time != null) times[key] = time.toLocal();
    }
    return times;
  }
}
