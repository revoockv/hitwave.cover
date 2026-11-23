import 'song_practice.dart';

/// Practice of one calendar day.
final class PracticeDay {
  /// The day (midnight, local time).
  final DateTime day;

  /// Practice time of the day.
  final Duration time;

  /// Number of takes recorded that day.
  final int takes;

  /// The songs practised that day, longest first.
  final List<SongPractice> songs;

  /// Creates a [PracticeDay].
  const PracticeDay({required this.day, required this.time, required this.takes, required this.songs});
}
