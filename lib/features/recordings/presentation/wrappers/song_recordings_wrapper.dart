import 'package:flutter/material.dart';
import 'package:watch_it/watch_it.dart';

import '../../domain/entities/recording.dart';
import '../di/recordings_getters.dart';

/// Gives [builder] the takes of the song [songId], newest first as stored; rebuilds when the takes change.
final class SongRecordingsWrapper extends WatchingWidget {
  /// The song.
  final String songId;

  /// Builds what shows the takes.
  final Widget Function(List<Recording> recordings) builder;

  /// Creates the wrapper.
  const SongRecordingsWrapper({required this.songId, required this.builder, super.key});

  @override
  Widget build(BuildContext context) {
    final List<Recording> recordings = watch(watchRecordingsUseCase()).value;
    return builder(recordings.where(_isOfSong).toList());
  }

  bool _isOfSong(Recording recording) => recording.songId == songId;
}
