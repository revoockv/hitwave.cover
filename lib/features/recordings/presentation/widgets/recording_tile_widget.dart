import 'package:flutter/material.dart';

import '../../../../core/presentation/theme.dart';
import '../../domain/entities/recording.dart';
import '../../domain/entities/recording_status.dart';
import '../../domain/entities/recording_version.dart';

/// One recording in the list: date, length, state, the original/enhanced switch, play and delete.
///
/// Knows nothing about use cases; every action is a callback.
final class RecordingTileWidget extends StatelessWidget {
  static const String _originalLabel = 'Оригінал';
  static const String _enhancedLabel = 'Покращений';
  static const String _enhancingLabel = 'Покращую…';
  static const String _failedLabel = 'Не покращено';
  static const String _retryLabel = 'Покращити ще раз';
  static const String _playLabel = 'Слухати';
  static const String _pauseLabel = 'Пауза';
  static const String _deleteLabel = 'Видалити';
  static const String _dateSeparator = '.';
  static const String _timeSeparator = ':';
  static const String _dateTimeSeparator = ' · ';
  static const String _zero = '0';
  static const int _millisecondsPerSecond = 1000;

  /// The recording.
  final Recording recording;

  /// The version chosen in the switch.
  final RecordingVersion version;

  /// Whether this recording is loaded in the player.
  final bool isLoaded;

  /// Whether it is playing now.
  final bool isPlaying;

  /// Played part, 0.0–1.0, while loaded.
  final double playedFraction;

  /// Progress of the enhancement of this take, 0.0–1.0, or `null` when unknown.
  final double? enhanceFraction;

  /// Called with the version chosen in the switch.
  final ValueChanged<RecordingVersion> onVersionChanged;

  /// Called by the play/pause button.
  final VoidCallback onPlayPressed;

  /// Called by the delete button.
  final VoidCallback onDeletePressed;

  /// Called by the "enhance again" button of a failed enhancement.
  final VoidCallback onRetryPressed;

  /// Creates a new [RecordingTileWidget].
  const RecordingTileWidget({
    super.key,
    required this.recording,
    required this.version,
    required this.isLoaded,
    required this.isPlaying,
    required this.playedFraction,
    required this.enhanceFraction,
    required this.onVersionChanged,
    required this.onPlayPressed,
    required this.onDeletePressed,
    required this.onRetryPressed,
  });

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final bool isEnhanced = recording.status == RecordingStatus.enhanced && recording.enhancedPath != null;

    return Card(
      margin: const EdgeInsets.only(bottom: AppTheme.spacingSmall),
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.spacingMedium),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Row(
              children: <Widget>[
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(_formatDate(recording.recordedAt), style: theme.textTheme.titleSmall),
                      Text(
                        '${_formatLength(recording)}$_dateTimeSeparator${_statusText(recording)}',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: recording.status == RecordingStatus.enhanceFailed
                              ? theme.colorScheme.error
                              : theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  tooltip: isLoaded && isPlaying ? _pauseLabel : _playLabel,
                  onPressed: onPlayPressed,
                  icon: Icon(isLoaded && isPlaying ? Icons.pause_circle : Icons.play_circle),
                ),
                IconButton(tooltip: _deleteLabel, onPressed: onDeletePressed, icon: const Icon(Icons.delete_outline)),
              ],
            ),
            const SizedBox(height: AppTheme.spacingSmall),
            SegmentedButton<RecordingVersion>(
              segments: <ButtonSegment<RecordingVersion>>[
                const ButtonSegment<RecordingVersion>(value: RecordingVersion.original, label: Text(_originalLabel)),
                ButtonSegment<RecordingVersion>(
                  value: RecordingVersion.enhanced,
                  label: const Text(_enhancedLabel),
                  enabled: isEnhanced,
                ),
              ],
              selected: <RecordingVersion>{isEnhanced ? version : RecordingVersion.original},
              onSelectionChanged: _onSelectionChanged,
            ),
            if (recording.status == RecordingStatus.enhancing) ...<Widget>[
              const SizedBox(height: AppTheme.spacingSmall),
              LinearProgressIndicator(value: enhanceFraction),
            ],
            if (recording.status == RecordingStatus.enhanceFailed)
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton.icon(
                  onPressed: onRetryPressed,
                  icon: const Icon(Icons.auto_fix_high),
                  label: const Text(_retryLabel),
                ),
              ),
            if (isLoaded) ...<Widget>[
              const SizedBox(height: AppTheme.spacingSmall),
              LinearProgressIndicator(value: playedFraction),
            ],
          ],
        ),
      ),
    );
  }

  void _onSelectionChanged(Set<RecordingVersion> selection) => onVersionChanged(selection.first);

  static String _statusText(Recording recording) => switch (recording.status) {
    RecordingStatus.enhancing => _enhancingLabel,
    RecordingStatus.enhanced => _enhancedLabel,
    RecordingStatus.enhanceFailed => recording.enhanceError ?? _failedLabel,
  };

  /// `dd.mm.yyyy · hh:mm`.
  static String _formatDate(DateTime date) {
    String two(int value) => value.toString().padLeft(AppTheme.twoDigits, _zero);
    return '${two(date.day)}$_dateSeparator${two(date.month)}$_dateSeparator${date.year}'
        '$_dateTimeSeparator${two(date.hour)}$_timeSeparator${two(date.minute)}';
  }

  /// Length of the part that is played, `m:ss`.
  static String _formatLength(Recording recording) {
    final double end = recording.keptToSeconds ?? recording.durationSeconds;
    final int seconds = ((end - recording.keptFromSeconds) * _millisecondsPerSecond).round() ~/ _millisecondsPerSecond;
    final String rest = (seconds % AppTheme.secondsPerMinute).toString().padLeft(AppTheme.twoDigits, _zero);
    return '${seconds ~/ AppTheme.secondsPerMinute}$_timeSeparator$rest';
  }
}
