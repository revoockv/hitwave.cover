import 'recording.dart';

/// How many covers (takes) every song has.
final class CoverCounts {
  /// No covers of any song.
  static final CoverCounts none = CoverCounts.fromRecordings(const <Recording>[]);

  final Map<String, int> _bySongId;

  /// Counts the [recordings] of every song.
  CoverCounts.fromRecordings(List<Recording> recordings) : _bySongId = <String, int>{} {
    for (final Recording recording in recordings) {
      _bySongId.update(recording.songId, _plusOne, ifAbsent: _one);
    }
  }

  /// The covers of the song [songId]; 0 when it has none.
  int of(String songId) => _bySongId[songId] ?? 0;

  static int _plusOne(int count) => count + 1;

  static int _one() => 1;
}
