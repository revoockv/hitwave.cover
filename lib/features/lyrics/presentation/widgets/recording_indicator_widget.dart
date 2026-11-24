import 'package:flutter/material.dart';
import 'package:watch_it/watch_it.dart';

import '../../../../core/presentation/theme.dart';
import '../../../recordings/domain/entities/recorder_state.dart';
import '../../../recordings/presentation/di/recordings_getters.dart';

/// A red dot, the time and the input level of the take of [songId] being recorded; nothing otherwise.
///
/// The only widget that watches the recorder ticks (several a second), so the lyrics page and its panel do not
/// rebuild with them.
final class RecordingIndicatorWidget extends WatchingWidget {
  /// Size of the red dot.
  static const double _dotSize = 10;

  /// Width of the input level bar.
  static const double _levelBarWidth = 48;

  /// Digits of the minutes and seconds.
  static const int _timeDigits = 2;

  /// Separator of minutes and seconds.
  static const String _timeSeparator = ':';

  /// Padding character of the time.
  static const String _zero = '0';

  /// The song whose take is shown.
  final String songId;

  /// Creates a new [RecordingIndicatorWidget].
  const RecordingIndicatorWidget({super.key, required this.songId});

  @override
  Widget build(BuildContext context) {
    final RecorderState recorder = watch(watchRecorderUseCase()).value;
    if (recorder is! RecordingRecorderState || recorder.songId != songId) return const SizedBox.shrink();
    final ColorScheme colorScheme = Theme.of(context).colorScheme;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Container(
          width: _dotSize,
          height: _dotSize,
          decoration: BoxDecoration(color: colorScheme.error, shape: BoxShape.circle),
        ),
        const SizedBox(width: AppTheme.spacingSmall),
        Text(
          _formatTime(recorder.elapsed),
          style: Theme.of(
            context,
          ).textTheme.labelLarge?.copyWith(fontFeatures: const <FontFeature>[FontFeature.tabularFigures()]),
        ),
        const SizedBox(width: AppTheme.spacingSmall),
        SizedBox(
          width: _levelBarWidth,
          child: LinearProgressIndicator(value: recorder.level, color: colorScheme.error),
        ),
      ],
    );
  }

  /// [time] as `mm:ss`.
  static String _formatTime(Duration time) {
    final int seconds = time.inSeconds;
    final String minutes = (seconds ~/ AppTheme.secondsPerMinute).toString().padLeft(_timeDigits, _zero);
    final String rest = (seconds % AppTheme.secondsPerMinute).toString().padLeft(_timeDigits, _zero);
    return '$minutes$_timeSeparator$rest';
  }
}
