import 'package:flutter/material.dart';
import 'package:watch_it/watch_it.dart';

import '../../../recordings/domain/entities/recorder_state.dart';
import '../../../recordings/presentation/di/recordings_getters.dart';
import '../widgets/recording_indicator_widget.dart';

/// Shows [RecordingIndicatorWidget] while a take of [songId] is recorded, and nothing otherwise.
///
/// The only wrapper that watches the recorder ticks (several a second), so the lyrics page and its panel do not
/// rebuild with them.
final class RecordingIndicatorWrapper extends WatchingWidget {
  /// The song whose take is shown.
  final String songId;

  /// Creates the wrapper.
  const RecordingIndicatorWrapper({super.key, required this.songId});

  @override
  Widget build(BuildContext context) {
    final RecorderState recorder = watch(watchRecorderUseCase()).value;
    if (recorder is! RecordingRecorderState || recorder.songId != songId) return const SizedBox.shrink();
    return RecordingIndicatorWidget(elapsed: recorder.elapsed, level: recorder.level);
  }
}
