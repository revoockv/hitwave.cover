import 'package:flutter/foundation.dart' show ValueNotifier;

import '../entities/song.dart';
import '../repositories/song_repository.dart';

/// Use case that exposes the current list of songs as a [ValueNotifier].
///
/// Allows the UI to reactively watch song list changes (add, update, delete).
/// Songs are sorted by name.
final class WatchListOfSongsUseCase {
  final SongRepository _repository;

  /// Creates a new [WatchListOfSongsUseCase].
  WatchListOfSongsUseCase(this._repository);

  /// Returns the songs [ValueNotifier].
  ///
  /// Emits a [List<Song>] sorted by song name.
  ValueNotifier<List<Song>> call() {
    return _repository.songs;
  }
}
