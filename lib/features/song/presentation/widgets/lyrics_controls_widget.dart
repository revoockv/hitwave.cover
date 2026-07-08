import 'package:flutter/material.dart';
import 'package:hitwave.cover/features/song/presentation/controllers/lyrics_page_controller.dart';

/// Controls bar widget for the lyrics page.
///
/// Displays the speed slider and play/stop button.
/// Extracted from [LyricsPage] to satisfy the [no_build_return] rule.
class LyricsControlsWidget extends StatelessWidget {
  /// The lyrics page controller.
  final LyricsPageController controller;

  /// Speed label text.
  final String speedLabel;

  /// Stop button label text.
  final String stopLabel;

  /// Start button label text.
  final String startLabel;

  /// Semi-transparent black overlay color.
  final Color overlayColor;

  /// Solid white color.
  final Color whiteColor;

  /// Solid black color.
  final Color blackColor;

  /// Horizontal padding for controls bar.
  final double controlsHorizontalPadding;

  /// Vertical padding for controls bar.
  final double controlsVerticalPadding;

  /// Border radius for controls bar.
  final double controlsRadius;

  /// Spacing between controls bar children.
  final double controlsSpacing;

  /// Font size for labels and values.
  final double labelFontSize;

  /// Slider track height.
  final double trackHeight;

  /// Spacing between play button and slider value.
  final double playButtonSpacing;

  /// Toggles auto-scrolling.
  final void Function() toggleScroll;

  /// Hides the keyboard.
  final void Function() hideKeyboard;

  /// Resets the auto-hide timer.
  final void Function() resetHideTimer;

  /// Creates a new [LyricsControlsWidget].
  const LyricsControlsWidget({
    super.key,
    required this.controller,
    required this.speedLabel,
    required this.stopLabel,
    required this.startLabel,
    required this.overlayColor,
    required this.whiteColor,
    required this.blackColor,
    required this.controlsHorizontalPadding,
    required this.controlsVerticalPadding,
    required this.controlsRadius,
    required this.controlsSpacing,
    required this.labelFontSize,
    required this.trackHeight,
    required this.playButtonSpacing,
    required this.toggleScroll,
    required this.hideKeyboard,
    required this.resetHideTimer,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedOpacity(
      opacity: controller.controlsVisible.value ? 1.0 : 0.0,
      duration: const Duration(milliseconds: 300),
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: controlsHorizontalPadding,
          vertical: controlsVerticalPadding,
        ),
        decoration: BoxDecoration(
          color: overlayColor,
          borderRadius: BorderRadius.vertical(
            bottom: Radius.circular(controlsRadius),
          ),
        ),
        child: Row(
          children: [
            SizedBox(width: controlsSpacing),
            Text(
              speedLabel,
              style: TextStyle(color: whiteColor, fontSize: labelFontSize),
            ),
            SizedBox(width: controlsSpacing),
            Expanded(
              child: ValueListenableBuilder<double>(
                valueListenable: controller.speed,
                builder: (context, speedValue, child) {
                  return SliderTheme(
                    data: SliderThemeData(
                      thumbColor: whiteColor,
                      trackHeight: trackHeight,
                    ),
                    child: Slider(
                      value: speedValue,
                      min: _minSpeed,
                      max: _maxSpeed,
                      divisions: _sliderDivisions,
                      label: speedValue.toStringAsFixed(1),
                      onChanged: (value) {
                        controller.speed.value = value;
                        hideKeyboard();
                        resetHideTimer();
                      },
                    ),
                  );
                },
              ),
            ),
            SizedBox(width: controlsSpacing),
            ValueListenableBuilder<double>(
              valueListenable: controller.speed,
              builder: (context, speedValue, child) {
                return Text(
                  speedValue.toStringAsFixed(1),
                  style: TextStyle(color: whiteColor, fontSize: labelFontSize),
                );
              },
            ),
            SizedBox(width: playButtonSpacing),
            ValueListenableBuilder<bool>(
              valueListenable: controller.isScrolling,
              builder: (context, isScrollingValue, child) {
                return ElevatedButton.icon(
                  onPressed: toggleScroll,
                  icon: Icon(
                    isScrollingValue ? Icons.stop : Icons.play_arrow,
                    color: blackColor,
                  ),
                  label: Text(isScrollingValue ? stopLabel : startLabel),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: whiteColor,
                    foregroundColor: blackColor,
                  ),
                );
              },
            ),
            SizedBox(width: playButtonSpacing),
          ],
        ),
      ),
    );
  }
}

const double _minSpeed = 0.0;
const double _maxSpeed = 1.0;
const int _sliderDivisions = 100;
