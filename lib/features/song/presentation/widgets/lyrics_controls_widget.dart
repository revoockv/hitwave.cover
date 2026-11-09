import 'package:flutter/material.dart';
import 'package:watch_it/watch_it.dart';

import '../../../../core/presentation/theme.dart';
import '../controllers/lyrics_page_controller.dart';

/// Floating control panel of the lyrics page.
///
/// Shows the play/stop button and the speed slider. Fades out (and stops
/// taking touches) when the controller hides the controls during scrolling.
/// Knows nothing about use cases: a released slider calls [onSpeedChosen].
final class LyricsControlsWidget extends WatchingWidget {
  /// Elevation of the panel.
  static const double _panelElevation = 6;

  /// Fade duration of the panel.
  static const Duration _fadeDuration = Duration(milliseconds: 250);

  /// Number of slider steps.
  static const int _sliderDivisions = 20;

  /// Digits after the point in the speed value.
  static const int _speedDigits = 1;

  /// UI state of the lyrics page.
  final LyricsPageController lyricsPageController;

  /// Called with the speed when the user releases the slider.
  final ValueChanged<double> onSpeedChosen;

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
    required this.speedLabel,
    required this.stopLabel,
    required this.startLabel,
  });

  @override
  Widget build(BuildContext context) {
    final bool visible = watch(lyricsPageController.controlsVisibilityController).value;
    final bool isScrolling = watch(lyricsPageController.scrollingController).value;
    final double speed = watch(lyricsPageController.speedController).value;
    final ColorScheme colorScheme = Theme.of(context).colorScheme;
    final TextTheme textTheme = Theme.of(context).textTheme;

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
                    Text(speedLabel, style: textTheme.labelLarge?.copyWith(color: colorScheme.onSurfaceVariant)),
                    Expanded(
                      child: Row(
                        children: <Widget>[
                          Expanded(
                            child: Slider(
                              value: speed,
                              min: LyricsPageController.minSpeed,
                              max: LyricsPageController.maxSpeed,
                              divisions: _sliderDivisions,
                              label: speed.toStringAsFixed(_speedDigits),
                              onChanged: _onSpeedChanged,
                              onChangeEnd: onSpeedChosen,
                            ),
                          ),
                          Text(
                            speed.toStringAsFixed(_speedDigits),
                            style: textTheme.labelLarge?.copyWith(
                              color: colorScheme.primary,
                              fontFeatures: const <FontFeature>[FontFeature.tabularFigures()],
                            ),
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
}
