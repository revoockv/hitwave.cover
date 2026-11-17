import 'song_difference.dart';

/// What a change does.
enum SyncChangeKind {
  /// Adds a song, a cover or practice sessions (or brings back something deleted).
  add,

  /// Deletes a song or a cover.
  delete,

  /// Gives a song the lyrics and album of the other device.
  update,
}

/// Which device a change is made on.
enum SyncDirection {
  /// From the other device to this one.
  toHere,

  /// From this device to the other one.
  toThere,
}

/// What a change is about.
enum SyncSubject {
  /// A song (with its covers when it is added).
  song,

  /// One cover.
  cover,

  /// Practice sessions.
  practice,
}

/// One change of a synchronisation that the user chooses to make or not.
///
/// A change not chosen is not made this time: both devices keep what they have, and the change
/// is offered again at the next synchronisation.
final class SyncChange {
  /// Id of the change, unique in one synchronisation.
  final String id;

  /// What it does.
  final SyncChangeKind kind;

  /// Which device it is made on.
  final SyncDirection direction;

  /// What it is about.
  final SyncSubject subject;

  /// "Artist — Name" of the song (of the cover's song for a cover); `null` when that song is gone
  /// or for practice sessions.
  final String? songTitle;

  /// When the cover was recorded; `null` unless [subject] is [SyncSubject.cover].
  final DateTime? coverRecordedAt;

  /// When the song or the cover was deleted on the device that deleted it; `null` when unknown.
  final DateTime? deletedAt;

  /// What differs in a song that is updated.
  final Set<SongDifference> differences;

  /// The covers that come with an added song, or the number of practice sessions.
  final int count;

  /// Whether it brings back something deleted on the device it is made on.
  final bool restores;

  /// Id of the change that cannot be made together with this one (deleting on one device or
  /// bringing back on the other, taking one version or the other); `null` when there is none.
  final String? excludes;

  /// Whether the change is chosen when the list is shown.
  final bool chosenFirst;

  /// Creates a [SyncChange].
  const SyncChange({
    required this.id,
    required this.kind,
    required this.direction,
    required this.subject,
    this.songTitle,
    this.coverRecordedAt,
    this.deletedAt,
    this.differences = const <SongDifference>{},
    this.count = 0,
    this.restores = false,
    this.excludes,
    this.chosenFirst = true,
  });
}
