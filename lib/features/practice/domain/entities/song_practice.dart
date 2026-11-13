/// How much one song was practised over some period.
final class SongPractice {
  /// Id of the song.
  final String songId;

  /// Practice time.
  final Duration time;

  /// Number of recorded takes.
  final int takes;

  /// Creates a [SongPractice].
  const SongPractice({required this.songId, required this.time, required this.takes});
}
