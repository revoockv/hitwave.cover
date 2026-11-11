import 'package:flutter/material.dart';
import 'package:watch_it/watch_it.dart';

import '../../../../core/presentation/theme.dart';
import '../controllers/lyrics_page_controller.dart';

/// Floating control panel of the lyrics page.
///
/// Shows the play/stop button, the speed slider and the slider of the space
/// above the lyrics. Fades out (and stops taking touches) when the controller
/// hides the controls during scrolling. Knows nothing about use cases: a
/// released slider calls [onSpeedChosen] or [onLeadInChosen].
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
  });

  @override
  Widget build(BuildContext context) {
    final bool visible = watch(lyricsPageController.controlsVisibilityController).value;
    final bool isScrolling = watch(lyricsPageController.scrollingController).value;
    final double speed = watch(lyricsPageController.speedController).value;
    final double leadIn = watch(lyricsPageController.leadInController).value;
    final ColorScheme colorScheme = Theme.of(context).colorScheme;

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
                      tooltip: isScrolling ? stopLabel : startLabel,
                      onPressed: lyricsPageController.toggleScroll,
                      icon: Icon(isScrolling ? Icons.pause : Icons.play_arrow),
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
