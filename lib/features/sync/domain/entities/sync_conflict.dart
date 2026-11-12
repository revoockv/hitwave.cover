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

  /// The song (and, for a cover, its date) the conflict is about.
  final String title;

  /// More about it (what changed), or `null`.
  final String? detail;

  /// Creates a [SyncConflict].
  const SyncConflict({required this.id, required this.kind, required this.title, required this.detail});

  /// The choices this conflict offers, the safe one (nothing is lost) first.
  List<SyncChoice> get choices => switch (kind) {
    SyncConflictKind.songChanged => const <SyncChoice>[SyncChoice.keepThis, SyncChoice.takeOther],
    _ => const <SyncChoice>[SyncChoice.restore, SyncChoice.delete],
  };
}
