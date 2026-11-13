import 'song_difference.dart';

/// What differs between the two devices.
enum SyncConflictKind {
  /// The song was deleted on this device and is still on the other one.
  songDeletedHere,

  /// The song was deleted on the other device and is still on this one.
  songDeletedThere,

  /// The song is on both devices with different lyrics, album, speed or space above the lyrics.
  songChanged,

  /// The cover was deleted on this device and is still on the other one.
  coverDeletedHere,

  /// The cover was deleted on the other device and is still on this one.
  coverDeletedThere,
}

/// What to do with a conflict.
enum SyncChoice {
  /// Delete it on the device that still has it.
  delete,

  /// Bring it back on the device where it was deleted.
  restore,

  /// Both devices keep the version of this device.
  keepThis,

  /// Both devices take the version of the other device.
  takeOther,
}

/// One difference between the devices that the user decides about.
final class SyncConflict {
  /// Id of the conflict, unique in one synchronisation.
  final String id;

  /// What differs.
  final SyncConflictKind kind;

  /// "Name — Artist" of the song (of the cover's song for a cover); `null` when that song is gone.
  final String? songTitle;

  /// When the cover was recorded; `null` for a song.
  final DateTime? coverRecordedAt;

  /// When the song or the cover was deleted; `null` when unknown or not deleted.
  final DateTime? deletedAt;

  /// What differs in a changed song.
  final Set<SongDifference> differences;

  /// Creates a [SyncConflict].
  const SyncConflict({
    required this.id,
    required this.kind,
    required this.songTitle,
    this.coverRecordedAt,
    this.deletedAt,
    this.differences = const <SongDifference>{},
  });

  /// The choices this conflict offers, the safe one (nothing is lost) first.
  List<SyncChoice> get choices => switch (kind) {
    SyncConflictKind.songChanged => const <SyncChoice>[SyncChoice.keepThis, SyncChoice.takeOther],
    _ => const <SyncChoice>[SyncChoice.restore, SyncChoice.delete],
  };
}
