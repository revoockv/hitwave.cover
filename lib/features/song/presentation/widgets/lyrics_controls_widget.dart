import 'package:flutter/material.dart';

import '../../../../core/presentation/theme.dart';
import '../controllers/lyrics_page_controller.dart';

/// Floating control panel of the lyrics page.
///
/// Shows the play/stop button and the speed slider. Fades out (and stops
/// taking touches) when the controller hides the controls during scrolling.
class LyricsControlsWidget extends StatelessWidget {
  /// Elevation of the panel.
  static const double _panelElevation = 6;

  /// Fade duration of the panel.
  static const Duration _fadeDuration = Duration(milliseconds: 250);

  /// Lowest scroll speed of the slider.
  static const double _minSpeed = 0.0;

  /// Highest scroll speed of the slider.
  static const double _maxSpeed = 1.0;

  /// Number of slider steps.
  static const int _sliderDivisions = 20;

  /// Digits after the point in the speed value.
  static const int _speedDigits = 1;

  /// The lyrics page controller.
  final LyricsPageController controller;

  /// Speed label text.
  final String speedLabel;

  /// Stop button label text.
  final String stopLabel;

  /// Start button label text.
  final String startLabel;

  /// Toggles auto-scrolling.
  final void Function() toggleScroll;

  /// Resets the auto-hide timer.
  final void Function() resetHideTimer;

  /// Creates a new [LyricsControlsWidget].
  const LyricsControlsWidget({
    super.key,
    required this.controller,
    required this.speedLabel,
    required this.stopLabel,
    required this.startLabel,
    required this.toggleScroll,
    required this.resetHideTimer,
  });

  @override
  Widget build(BuildContext context) {
    final ColorScheme colorScheme = Theme.of(context).colorScheme;
    final TextTheme textTheme = Theme.of(context).textTheme;

    return ValueListenableBuilder<bool>(
      valueListenable: controller.controlsVisible,
      builder: (BuildContext context, bool visible, Widget? child) {
        return IgnorePointer(
          ignoring: !visible,
          child: AnimatedOpacity(opacity: visible ? 1.0 : 0.0, duration: _fadeDuration, child: child),
        );
      },
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(AppTheme.spacingMedium, 0, AppTheme.spacingMedium, AppTheme.spacingMedium),
          child: Material(
            color: colorScheme.surfaceContainerHigh,
            elevation: _panelElevation,
            borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppTheme.spacingMedium, vertical: AppTheme.spacingSmall),
              child: Row(
                children: <Widget>[
                  ValueListenableBuilder<bool>(
                    valueListenable: controller.isScrolling,
                    builder: (BuildContext context, bool isScrolling, Widget? child) {
                      return IconButton.filled(
                        iconSize: AppTheme.spacingLarge,
                        tooltip: isScrolling ? stopLabel : startLabel,
                        onPressed: () => _onTogglePressed(isScrolling),
                        icon: Icon(isScrolling ? Icons.pause : Icons.play_arrow),
                      );
                    },
                  ),
                  const SizedBox(width: AppTheme.spacingSmall),
                  Text(speedLabel, style: textTheme.labelLarge?.copyWith(color: colorScheme.onSurfaceVariant)),
                  Expanded(
                    child: ValueListenableBuilder<double>(
                      valueListenable: controller.speed,
                      builder: (BuildContext context, double speed, Widget? child) {
                        return Row(
                          children: <Widget>[
                            Expanded(
                              child: Slider(
                                value: speed,
                                min: _minSpeed,
                                max: _maxSpeed,
                                divisions: _sliderDivisions,
                                label: speed.toStringAsFixed(_speedDigits),
                                onChanged: _onSpeedChanged,
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
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _onTogglePressed(bool wasScrolling) {
    toggleScroll();
    if (wasScrolling) {
      resetHideTimer();
    }
  }

  void _onSpeedChanged(double value) {
    controller.speed.value = value;
    resetHideTimer();
  }
}
