import 'package:flutter/foundation.dart' show ValueListenable;
import 'package:flutter/material.dart';
import 'package:watch_it/watch_it.dart';

import '../../domain/entities/playback_state.dart';
import '../di/recordings_getters.dart';

/// How much of the loaded recording is played.
///
/// The only wrapper that watches the playback position, which changes many times a second, so the list and the tiles
/// do not rebuild with it. It gives a plain [LinearProgressIndicator] the fraction.
final class PlaybackProgressWrapper extends WatchingWidget {
  /// Creates a new [PlaybackProgressWrapper].
  const PlaybackProgressWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    final double fraction = watchPropertyValue(_fractionOf, target: watchPlaybackUseCase());
    return LinearProgressIndicator(value: fraction);
  }

  /// Played part, 0.0–1.0.
  static double _fractionOf(ValueListenable<PlaybackState> playback) {
    final int total = playback.value.duration.inMilliseconds;
    if (total <= 0) return 0;
    return (playback.value.position.inMilliseconds / total).clamp(0.0, 1.0);
  }
}
