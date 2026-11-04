import 'package:flutter/foundation.dart' show ValueListenable;

import '../entities/song.dart';
import '../repositories/song_repository.dart';

/// Use case that exposes the current list of songs as a [ValueListenable].
///
/// Allows the UI to reactively watch song list changes (add, update, delete).
/// Songs are sorted by name.
final class WatchListOfSongsUseCase {
  final SongRepository _repository;

  /// Creates a new [WatchListOfSongsUseCase].
  WatchListOfSongsUseCase(this._repository);

  /// Returns the songs [ValueListenable].
  ///
  /// Emits a [List<Song>] sorted by song name.
  ValueListenable<List<Song>> call() {
    return _repository.watchSongs();
  }
}
