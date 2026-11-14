import '../../../../core/presentation/widgets/surface_widget.dart';
import 'package:flutter/material.dart';

import '../../../../core/presentation/theme.dart';
import '../../domain/entities/recording.dart';
import '../../domain/entities/recording_status.dart';
import '../../domain/entities/recording_version.dart';
import '../../../../core/presentation/l10n/app_translations.dart';
import '../l10n/recordings_texts.dart';

/// One recording in the list: date, length, state, the original/enhanced switch, play, share,
/// show in folder (desktop) and delete.
///
/// Knows nothing about use cases; every action is a callback.
final class RecordingTileWidget extends StatelessWidget {
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

  /// Called by the share button.
  final VoidCallback onSharePressed;

  /// Whether the MP3 for sharing is being made (the share button waits).
  final bool isSharing;

  /// Called by the folder button; `null` hides it (no file manager on this platform).
  final VoidCallback? onShowInFolderPressed;

  /// Called by the "enhance" button of a take not enhanced yet, the "enhance again" button of a
  /// failed enhancement, and the one in the actions of an enhanced take.
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
    required this.onSharePressed,
    this.isSharing = false,
    required this.onShowInFolderPressed,
    required this.onRetryPressed,
  });

  @override
  Widget build(BuildContext context) {
    final Translations t = context.t;
    final ThemeData theme = Theme.of(context);
    final bool isEnhanced = recording.status == RecordingStatus.enhanced && recording.enhancedPath != null;

    return SurfaceWidget(
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
                        '${_formatLength(recording)}$_dateTimeSeparator${_statusText(context.t, recording)}',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: recording.status == RecordingStatus.enhanceFailed || recording.isSilent
                              ? theme.colorScheme.error
                              : theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  tooltip: isLoaded && isPlaying ? t.recordings.pause : t.recordings.play,
                  onPressed: onPlayPressed,
                  icon: Icon(isLoaded && isPlaying ? Icons.pause_circle : Icons.play_circle),
                ),
                IconButton(
                  tooltip: isSharing ? t.recordings.preparingMp3 : t.recordings.share,
                  onPressed: isSharing ? null : onSharePressed,
                  icon: isSharing
                      ? const SizedBox.square(
                          dimension: AppTheme.loadingIndicatorSize,
                          child: CircularProgressIndicator(strokeWidth: AppTheme.loadingIndicatorStroke),
                        )
                      : const Icon(Icons.share_outlined),
                ),
                if (onShowInFolderPressed != null)
                  IconButton(
                    tooltip: t.recordings.showInFolder,
                    onPressed: onShowInFolderPressed,
                    icon: const Icon(Icons.folder_open_outlined),
                  ),
                if (recording.status == RecordingStatus.enhanced)
                  IconButton(
                    tooltip: t.recordings.retry,
                    onPressed: onRetryPressed,
                    icon: const Icon(Icons.auto_fix_high),
                  ),
                IconButton(
                  tooltip: t.common.delete,
                  onPressed: onDeletePressed,
                  icon: const Icon(Icons.delete_outline),
                ),
              ],
            ),
            const SizedBox(height: AppTheme.spacingSmall),
            SegmentedButton<RecordingVersion>(
              segments: <ButtonSegment<RecordingVersion>>[
                ButtonSegment<RecordingVersion>(value: RecordingVersion.original, label: Text(t.recordings.original)),
                ButtonSegment<RecordingVersion>(
                  value: RecordingVersion.enhanced,
                  label: Text(t.recordings.enhanced),
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
            if (recording.status == RecordingStatus.recorded || recording.status == RecordingStatus.enhanceFailed)
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton.icon(
                  onPressed: onRetryPressed,
                  icon: const Icon(Icons.auto_fix_high),
                  label: Text(
                    recording.status == RecordingStatus.recorded ? t.recordings.enhanceNow : t.recordings.retry,
                  ),
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

  static String _statusText(Translations t, Recording recording) => recording.isSilent
      ? t.recordings.silent
      : switch (recording.status) {
          RecordingStatus.recorded => t.recordings.notEnhanced,
          RecordingStatus.enhancing => t.recordings.enhancing,
          RecordingStatus.enhanced => t.recordings.enhanced,
          RecordingStatus.enhanceFailed => recording.enhanceFailure?.text(t) ?? t.recordings.notEnhanced,
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
