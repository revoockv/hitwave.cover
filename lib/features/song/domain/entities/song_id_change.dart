/// A song id that stopped being valid, so data kept elsewhere for that song (its recordings on
/// the device) can follow it.
sealed class SongIdChange {
  const SongIdChange();
}

/// The song [fromId] now lives under [toId] (moved from the device into the account).
final class SongMovedIdChange extends SongIdChange {
  /// The old id.
  final String fromId;

  /// The new id.
  final String toId;

  /// Creates a [SongMovedIdChange].
  const SongMovedIdChange({required this.fromId, required this.toId});
}

/// The song [songId] was deleted.
final class SongDeletedIdChange extends SongIdChange {
  /// The id of the deleted song.
  final String songId;

  /// Artist of the deleted song, when it was known (the sync remembers deletions by it).
  final String? author;

  /// Name of the deleted song, when it was known.
  final String? name;

  /// Creates a [SongDeletedIdChange].
  const SongDeletedIdChange(this.songId, {this.author, this.name});
}
