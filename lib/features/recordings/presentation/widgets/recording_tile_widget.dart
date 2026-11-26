import '../../../../core/presentation/widgets/surface_widget.dart';
import 'package:flutter/material.dart';

import '../../../../core/presentation/theme.dart';
import '../../domain/entities/recording.dart';
import '../../domain/entities/recording_status.dart';
import '../../domain/entities/recording_version.dart';

/// The texts of the recordings widgets.
final class RecordingsTexts {
  /// Tooltip of the play button.
  final String playTooltip;

  /// Tooltip of the play button while the take plays.
  final String pauseTooltip;

  /// Tooltip of the share button.
  final String shareTooltip;

  /// Tooltip of the share button while the MP3 is made.
  final String preparingMp3Tooltip;

  /// Tooltip of the show-in-folder button.
  final String showInFolderTooltip;

  /// Tooltip and label of enhancing again.
  final String retryLabel;

  /// Label of enhancing a take that was not enhanced yet.
  final String enhanceNowLabel;

  /// Tooltip of the delete button.
  final String deleteTooltip;

  /// Label of the original version.
  final String originalLabel;

  /// Label of the enhanced version.
  final String enhancedLabel;

  /// The state of a take as text ("not enhanced", "enhancing…", the failure).
  final String Function(Recording recording) statusOf;

  /// Title of the delete dialog.
  final String deleteTitle;

  /// What deleting a take does.
  final String deleteMessage;

  /// Label of the cancel button.
  final String cancelLabel;

  /// Label of the delete button.
  final String deleteLabel;

  /// Title of the microphone picker.
  final String microphoneTitle;

  /// Hint of the microphone picker.
  final String microphoneHint;

  /// Name of the input the system uses.
  final String systemMicrophoneLabel;

  /// Creates the texts.
  const RecordingsTexts({
    required this.playTooltip,
    required this.pauseTooltip,
    required this.shareTooltip,
    required this.preparingMp3Tooltip,
    required this.showInFolderTooltip,
    required this.retryLabel,
    required this.enhanceNowLabel,
    required this.deleteTooltip,
    required this.originalLabel,
    required this.enhancedLabel,
    required this.statusOf,
    required this.deleteTitle,
    required this.deleteMessage,
    required this.cancelLabel,
    required this.deleteLabel,
    required this.microphoneTitle,
    required this.microphoneHint,
    required this.systemMicrophoneLabel,
  });
}

/// One recording in the list: date, length, state, the original/enhanced switch, play, share,
/// show in folder (desktop) and delete.
///
/// Dumb: every action is a callback; the progress bars of enhancing and playing come as widgets (their wrappers watch
/// the fast progress).
final class RecordingTileWidget extends StatelessWidget {
  static const String _dateSeparator = '.';
  static const String _timeSeparator = ':';
  static const String _dateTimeSeparator = ' · ';
  static const String _zero = '0';
  static const int _millisecondsPerSecond = 1000;

  /// Narrower than this, the actions go to a line of their own under the date.
  static const double _oneLineWidth = 360;

  /// The recording.
  final Recording recording;

  /// The version chosen in the switch.
  final RecordingVersion version;

  /// Whether this recording is loaded in the player.
  final bool isLoaded;

  /// Whether it is playing now.
  final bool isPlaying;

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

  /// The texts.
  final RecordingsTexts texts;

  /// The progress of enhancing, shown while the take is enhanced.
  final Widget enhanceProgress;

  /// The progress of playing, shown while the take is loaded; `null` when it is not.
  final Widget? playbackProgress;

  /// Creates a new [RecordingTileWidget].
  const RecordingTileWidget({
    super.key,
    required this.recording,
    required this.version,
    required this.isLoaded,
    required this.isPlaying,
    required this.onVersionChanged,
    required this.onPlayPressed,
    required this.onDeletePressed,
    required this.onSharePressed,
    this.isSharing = false,
    required this.onShowInFolderPressed,
    required this.onRetryPressed,
    required this.texts,
    required this.enhanceProgress,
    this.playbackProgress,
  });

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final bool isEnhanced = recording.status == RecordingStatus.enhanced && recording.enhancedPath != null;

    return SurfaceWidget(
      margin: const EdgeInsets.only(bottom: AppTheme.spacingSmall),
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.spacingMedium),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            LayoutBuilder(
              builder: (BuildContext context, BoxConstraints constraints) {
                final Widget play = IconButton(
                  tooltip: isLoaded && isPlaying ? texts.pauseTooltip : texts.playTooltip,
                  onPressed: onPlayPressed,
                  icon: Icon(isLoaded && isPlaying ? Icons.pause_circle : Icons.play_circle),
                );
                final List<Widget> actions = <Widget>[
                  IconButton(
                    tooltip: isSharing ? texts.preparingMp3Tooltip : texts.shareTooltip,
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
                      tooltip: texts.showInFolderTooltip,
                      onPressed: onShowInFolderPressed,
                      icon: const Icon(Icons.folder_open_outlined),
                    ),
                  if (recording.status == RecordingStatus.enhanced)
                    IconButton(
                      tooltip: texts.retryLabel,
                      onPressed: onRetryPressed,
                      icon: const Icon(Icons.auto_fix_high),
                    ),
                  IconButton(
                    tooltip: texts.deleteTooltip,
                    onPressed: onDeletePressed,
                    icon: const Icon(Icons.delete_outline),
                  ),
                ];
                final Widget details = Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(_formatDate(recording.recordedAt), style: theme.textTheme.titleSmall),
                      Text(
                        '${_formatLength(recording)}$_dateTimeSeparator${texts.statusOf(recording)}',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: recording.status == RecordingStatus.enhanceFailed || recording.isSilent
                              ? theme.colorScheme.error
                              : theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                );
                if (constraints.maxWidth >= _oneLineWidth) {
                  return Row(children: <Widget>[details, play, ...actions]);
                }
                // A narrow phone: the date and the play button on top, the other actions under them.
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    Row(children: <Widget>[details, play]),
                    Row(mainAxisAlignment: MainAxisAlignment.end, children: actions),
                  ],
                );
              },
            ),
            const SizedBox(height: AppTheme.spacingSmall),
            SegmentedButton<RecordingVersion>(
              segments: <ButtonSegment<RecordingVersion>>[
                ButtonSegment<RecordingVersion>(
                  value: RecordingVersion.original,
                  label: _OneLineLabelWidget(texts.originalLabel),
                ),
                ButtonSegment<RecordingVersion>(
                  value: RecordingVersion.enhanced,
                  label: _OneLineLabelWidget(texts.enhancedLabel),
                  enabled: isEnhanced,
                ),
              ],
              selected: <RecordingVersion>{isEnhanced ? version : RecordingVersion.original},
              onSelectionChanged: _onSelectionChanged,
            ),
            if (recording.status == RecordingStatus.enhancing) ...<Widget>[
              const SizedBox(height: AppTheme.spacingSmall),
              enhanceProgress,
            ],
            if (recording.status == RecordingStatus.recorded || recording.status == RecordingStatus.enhanceFailed)
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton.icon(
                  onPressed: onRetryPressed,
                  icon: const Icon(Icons.auto_fix_high),
                  label: Text(recording.status == RecordingStatus.recorded ? texts.enhanceNowLabel : texts.retryLabel),
                ),
              ),
            if (playbackProgress case final Widget progress) ...<Widget>[
              const SizedBox(height: AppTheme.spacingSmall),
              progress,
            ],
          ],
        ),
      ),
    );
  }

  void _onSelectionChanged(Set<RecordingVersion> selection) => onVersionChanged(selection.first);

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

/// A label on one line that gets smaller instead of breaking a word.
final class _OneLineLabelWidget extends StatelessWidget {
  final String text;

  const _OneLineLabelWidget(this.text);

  @override
  Widget build(BuildContext context) =>
      FittedBox(fit: BoxFit.scaleDown, child: Text(text, maxLines: 1, softWrap: false));
}
