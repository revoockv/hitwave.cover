import 'package:flutter/material.dart';
import 'package:watch_it/watch_it.dart';

import '../../../../core/presentation/theme.dart';
import '../controllers/lyrics_page_controller.dart';

/// Floating control panel of the lyrics page.
///
/// Shows the play/stop button, the speed slider, the slider of the space above
/// the lyrics and the record / trim-silence checkboxes; while a take is being
/// recorded, a red dot with the time and the input level. Fades out (and stops
/// taking touches) when the controller hides the controls during scrolling.
/// Knows nothing about use cases: the button calls [onPlayPressed], a released
/// slider calls [onSpeedChosen] or [onLeadInChosen].
final class LyricsControlsWidget extends WatchingWidget {
  /// Elevation of the panel.
  static const double _panelElevation = 6;

  /// Fade duration of the panel.
  static const Duration _fadeDuration = Duration(milliseconds: 250);

  /// Number of slider steps.
  static const int _sliderDivisions = 20;

  /// Number of steps of the space slider.
  static const int _leadInDivisions = 16;

  /// Width of the slider labels, so both sliders start at the same place.
  static const double _labelWidth = 80;

  /// Digits after the point in the speed value.
  static const int _speedDigits = 1;

  /// Shows the space as percent of the screen height.
  static const int _percent = 100;

  /// Percent sign after the space value.
  static const String _percentSign = '%';

  /// Size of the red dot shown while recording.
  static const double _recordingDotSize = 10;

  /// Width of the input level bar.
  static const double _levelBarWidth = 48;

  /// Digits of the minutes and seconds of the recording time.
  static const int _timeDigits = 2;

  /// Separator of minutes and seconds.
  static const String _timeSeparator = ':';

  /// Padding character of the recording time.
  static const String _zero = '0';

  /// UI state of the lyrics page.
  final LyricsPageController lyricsPageController;

  /// Called with the speed when the user releases the slider.
  final ValueChanged<double> onSpeedChosen;

  /// Called with the space above the lyrics when the user releases its slider.
  final ValueChanged<double> onLeadInChosen;

  /// Label of the space slider.
  final String leadInLabel;

  /// Speed label text.
  final String speedLabel;

  /// Stop button label text.
  final String stopLabel;

  /// Start button label text.
  final String startLabel;

  /// Label of the button while a take is being recorded.
  final String stopRecordingLabel;

  /// Label of the record checkbox.
  final String recordLabel;

  /// Label of the trim-silence checkbox.
  final String trimSilenceLabel;

  /// Called when the play/pause button is pressed.
  final VoidCallback onPlayPressed;

  /// Time of the take being recorded, or `null` when nothing is recorded.
  final Duration? recordingElapsed;

  /// Input level of the take being recorded, 0.0–1.0.
  final double recordingLevel;

  /// Creates a new [LyricsControlsWidget].
  const LyricsControlsWidget({
    super.key,
    required this.lyricsPageController,
    required this.onSpeedChosen,
    required this.onLeadInChosen,
    required this.leadInLabel,
    required this.speedLabel,
    required this.stopLabel,
    required this.startLabel,
    required this.stopRecordingLabel,
    required this.recordLabel,
    required this.trimSilenceLabel,
    required this.onPlayPressed,
    required this.recordingElapsed,
    required this.recordingLevel,
  });

  @override
  Widget build(BuildContext context) {
    final bool visible = watch(lyricsPageController.controlsVisibilityController).value;
    final bool isScrolling = watch(lyricsPageController.scrollingController).value;
    final double speed = watch(lyricsPageController.speedController).value;
    final double leadIn = watch(lyricsPageController.leadInController).value;
    final bool record = watch(lyricsPageController.recordController).value;
    final bool trimSilence = watch(lyricsPageController.trimSilenceController).value;
    final ColorScheme colorScheme = Theme.of(context).colorScheme;
    final Duration? elapsed = recordingElapsed;
    final bool isRecording = elapsed != null;
    final bool canChangeOptions = !isScrolling && !isRecording;

    return IgnorePointer(
      ignoring: !visible,
      child: AnimatedOpacity(
        opacity: visible ? 1.0 : 0.0,
        duration: _fadeDuration,
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              AppTheme.spacingMedium,
              0,
              AppTheme.spacingMedium,
              AppTheme.spacingMedium,
            ),
            child: Material(
              color: colorScheme.surfaceContainerHigh,
              elevation: _panelElevation,
              borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppTheme.spacingMedium,
                  vertical: AppTheme.spacingSmall,
                ),
                child: Row(
                  children: <Widget>[
                    IconButton.filled(
                      iconSize: AppTheme.spacingLarge,
                      tooltip: isRecording ? stopRecordingLabel : (isScrolling ? stopLabel : startLabel),
                      onPressed: onPlayPressed,
                      style: isRecording ? IconButton.styleFrom(backgroundColor: colorScheme.error) : null,
                      icon: Icon(isRecording ? Icons.stop : (isScrolling ? Icons.pause : Icons.play_arrow)),
                    ),
                    const SizedBox(width: AppTheme.spacingSmall),
                    Expanded(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: <Widget>[
                          _SliderRowWidget(
                            label: speedLabel,
                            labelWidth: _labelWidth,
                            value: speed,
                            min: LyricsPageController.minSpeed,
                            max: LyricsPageController.maxSpeed,
                            divisions: _sliderDivisions,
                            valueText: speed.toStringAsFixed(_speedDigits),
                            onChanged: _onSpeedChanged,
                            onChangeEnd: onSpeedChosen,
                          ),
                          _SliderRowWidget(
                            label: leadInLabel,
                            labelWidth: _labelWidth,
                            value: leadIn,
                            min: LyricsPageController.minLeadIn,
                            max: LyricsPageController.maxLeadIn,
                            divisions: _leadInDivisions,
                            valueText: '${(leadIn * _percent).round()}$_percentSign',
                            onChanged: _onLeadInChanged,
                            onChangeEnd: onLeadInChosen,
                          ),
                          Row(
                            children: <Widget>[
                              _CheckboxWidget(
                                label: recordLabel,
                                value: record,
                                onChanged: canChangeOptions ? _onRecordChanged : null,
                              ),
                              _CheckboxWidget(
                                label: trimSilenceLabel,
                                value: trimSilence,
                                onChanged: canChangeOptions ? _onTrimSilenceChanged : null,
                              ),
                              const Spacer(),
                              if (elapsed != null) ...<Widget>[
                                Container(
                                  width: _recordingDotSize,
                                  height: _recordingDotSize,
                                  decoration: BoxDecoration(color: colorScheme.error, shape: BoxShape.circle),
                                ),
                                const SizedBox(width: AppTheme.spacingSmall),
                                Text(
                                  _formatTime(elapsed),
                                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                                    fontFeatures: const <FontFeature>[FontFeature.tabularFigures()],
                                  ),
                                ),
                                const SizedBox(width: AppTheme.spacingSmall),
                                SizedBox(
                                  width: _levelBarWidth,
                                  child: LinearProgressIndicator(value: recordingLevel, color: colorScheme.error),
                                ),
                              ],
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _onSpeedChanged(double value) {
    lyricsPageController.speedController.value = value;
    lyricsPageController.resetHideTimer();
  }

  void _onLeadInChanged(double value) {
    lyricsPageController.leadInController.value = value;
    lyricsPageController.resetHideTimer();
  }

  void _onRecordChanged(bool? value) {
    lyricsPageController.recordController.value = value ?? false;
    lyricsPageController.resetHideTimer();
  }

  void _onTrimSilenceChanged(bool? value) {
    lyricsPageController.trimSilenceController.value = value ?? false;
    lyricsPageController.resetHideTimer();
  }

  /// [time] as `mm:ss`.
  static String _formatTime(Duration time) {
    final int seconds = time.inSeconds;
    final String minutes = (seconds ~/ AppTheme.secondsPerMinute).toString().padLeft(_timeDigits, _zero);
    final String rest = (seconds % AppTheme.secondsPerMinute).toString().padLeft(_timeDigits, _zero);
    return '$minutes$_timeSeparator$rest';
  }
}

/// A checkbox with its label; the whole row toggles it.
final class _CheckboxWidget extends StatelessWidget {
  /// Text after the box.
  final String label;

  /// Whether it is checked.
  final bool value;

  /// Called with the new value; `null` disables it.
  final ValueChanged<bool?>? onChanged;

  /// Creates a new [_CheckboxWidget].
  const _CheckboxWidget({required this.label, required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final ValueChanged<bool?>? changed = onChanged;
    return InkWell(
      borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
      onTap: changed == null ? null : () => changed(!value),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Checkbox(value: value, onChanged: changed, visualDensity: VisualDensity.compact),
          Text(label, style: Theme.of(context).textTheme.labelLarge),
          const SizedBox(width: AppTheme.spacingSmall),
        ],
      ),
    );
  }
}

/// One labelled slider of the control panel with its value on the right.
final class _SliderRowWidget extends StatelessWidget {
  /// Text before the slider.
  final String label;

  /// Width of [label], the same for every row.
  final double labelWidth;

  /// Current value.
  final double value;

  /// Lowest value.
  final double min;

  /// Highest value.
  final double max;

  /// Number of slider steps.
  final int divisions;

  /// [value] as shown on the right and in the slider bubble.
  final String valueText;

  /// Called while the user drags.
  final ValueChanged<double> onChanged;

  /// Called when the user releases the slider.
  final ValueChanged<double> onChangeEnd;

  /// Creates a new [_SliderRowWidget].
  const _SliderRowWidget({
    required this.label,
    required this.labelWidth,
    required this.value,
    required this.min,
    required this.max,
    required this.divisions,
    required this.valueText,
    required this.onChanged,
    required this.onChangeEnd,
  });

  @override
  Widget build(BuildContext context) {
    final ColorScheme colorScheme = Theme.of(context).colorScheme;
    final TextTheme textTheme = Theme.of(context).textTheme;

    return Row(
      children: <Widget>[
        SizedBox(
          width: labelWidth,
          child: Text(label, style: textTheme.labelLarge?.copyWith(color: colorScheme.onSurfaceVariant)),
        ),
        Expanded(
          child: Slider(
            value: value,
            min: min,
            max: max,
            divisions: divisions,
            label: valueText,
            onChanged: onChanged,
            onChangeEnd: onChangeEnd,
          ),
        ),
        Text(
          valueText,
          style: textTheme.labelLarge?.copyWith(
            color: colorScheme.primary,
            fontFeatures: const <FontFeature>[FontFeature.tabularFigures()],
          ),
        ),
      ],
    );
  }
}
