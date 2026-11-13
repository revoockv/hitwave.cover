import 'package:flutter/foundation.dart' show ValueListenable;

import '../entities/playback_state.dart';
import '../repositories/playback_repository.dart';

/// Use case that exposes what the player is doing.
final class WatchPlaybackUseCase {
  final PlaybackRepository _repository;

  /// Creates a [WatchPlaybackUseCase].
  WatchPlaybackUseCase(this._repository);

  /// Returns the playback state.
  ValueListenable<PlaybackState> call() {
    return _repository.watchPlayback();
  }
}
