/// Plays one audio file at a time. May throw; the repository converts errors to failures.
abstract interface class AudioPlayerDataSource {
  /// Position of the playing part, while something is loaded.
  Stream<Duration> get positions;

  /// Whether it is playing (`false` when paused or stopped).
  Stream<bool> get playingChanges;

  /// Emits when the loaded part played to its end.
  Stream<void> get completions;

  /// Loads the part [start]–[end] of the file at [path] (the whole file when `null`) and returns
  /// the length of that part.
  Future<Duration> open(String path, {Duration? start, Duration? end});

  /// Plays from the current position; returns once it started.
  Future<void> play();

  /// Pauses.
  Future<void> pause();

  /// Stops and unloads.
  Future<void> stop();

  /// Releases the player.
  Future<void> dispose();
}
