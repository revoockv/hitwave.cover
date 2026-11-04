import 'package:flutter/material.dart';
import 'package:hitwave.cover/features/song/presentation/controllers/lyrics_page_controller.dart';
import '../../../../core/presentation/theme.dart';

/// Controls bar widget for the lyrics page.
///
/// Displays the speed slider and play/stop button with a frosted-glass
/// aesthetic. Auto-hides after inactivity when scrolling is active.
/// Extracted from [LyricsPage] to satisfy the [no_build_return] rule.
class LyricsControlsWidget extends StatelessWidget {
  /// Panel corner radius.
  static const double _panelRadius = 20;

  /// Panel surface alpha.
  static const double _panelSurfaceAlpha = 0.85;

  /// Shadow blur radius.
  static const double _shadowBlurRadius = 16;

  /// Shadow alpha.
  static const double _shadowAlpha = 0.3;

  /// Shadow offset Y.
  static const double _shadowOffsetY = 2;

  /// Circle avatar radius.
  static const double _avatarRadius = 20;

  /// Icon size inside play/stop button.
  static const double _iconSize = 20;

  /// Slider track height.
  static const double _trackHeight = 4;

  /// Slider thumb radius.
  static const double _thumbRadius = 8;

  /// Slider overlay radius.
  static const double _overlayRadius = 12;

  /// Inactive track alpha.
  static const double _inactiveTrackAlpha = 0.5;

  /// Slider overlay alpha.
  static const double _overlayAlpha = 0.2;

  /// Shadow color (black).
  static const Color _shadowColor = Colors.black;

  /// Lowest scroll speed of the slider.
  static const double _minSpeed = 0.0;

  /// Highest scroll speed of the slider.
  static const double _maxSpeed = 1.0;

  /// Number of slider steps.
  static const int _sliderDivisions = 100;

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

    return AnimatedOpacity(
      opacity: controller.controlsVisible.value ? 1.0 : 0.0,
      duration: const Duration(milliseconds: 300),
      child: Container(
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: colorScheme.surface.withValues(alpha: LyricsControlsWidget._panelSurfaceAlpha),
          borderRadius: BorderRadius.circular(LyricsControlsWidget._panelRadius),
          boxShadow: [
            BoxShadow(
              color: LyricsControlsWidget._shadowColor.withValues(alpha: LyricsControlsWidget._shadowAlpha),
              blurRadius: LyricsControlsWidget._shadowBlurRadius,
              offset: const Offset(0, -LyricsControlsWidget._shadowOffsetY),
            ),
          ],
        ),
        child: Row(
          children: [
            ValueListenableBuilder<bool>(
              valueListenable: controller.isScrolling,
              builder: (context, isScrollingValue, child) {
                return Padding(
                  padding: const EdgeInsets.only(right: 12),
                  child: CircleAvatar(
                    radius: LyricsControlsWidget._avatarRadius,
                    backgroundColor: isScrollingValue
                        ? colorScheme.primary
                        : colorScheme.primaryContainer,
                    child: IconButton(
                      onPressed: () {
                        toggleScroll();
                        if (isScrollingValue) {
                          resetHideTimer();
                        }
                      },
                      icon: Icon(
                        isScrollingValue ? Icons.stop : Icons.play_arrow,
                        color: isScrollingValue
                            ? colorScheme.onPrimary
                            : colorScheme.onPrimaryContainer,
                        size: LyricsControlsWidget._iconSize,
                      ),
                    ),
                  ),
                );
              },
            ),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(bottom: AppTheme.spacingTiny),
                    child: Text(
                      speedLabel,
                      style: textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                  ValueListenableBuilder<double>(
                    valueListenable: controller.speed,
                    builder: (context, speedValue, child) {
                      return Row(
                        children: [
                          Expanded(
                            child: SliderTheme(
                              data: SliderThemeData(
                                trackHeight: LyricsControlsWidget._trackHeight,
                                thumbShape: const RoundSliderThumbShape(enabledThumbRadius: LyricsControlsWidget._thumbRadius),
                                overlayShape: const RoundSliderOverlayShape(overlayRadius: LyricsControlsWidget._overlayRadius),
                                activeTrackColor: colorScheme.primary,
                                inactiveTrackColor: colorScheme.surfaceContainerHighest.withValues(alpha: LyricsControlsWidget._inactiveTrackAlpha),
                                thumbColor: colorScheme.primary,
                                overlayColor: colorScheme.primary.withValues(alpha: LyricsControlsWidget._overlayAlpha),
                              ),
                              child: Slider(
                                value: speedValue,
                                min: _minSpeed,
                                max: _maxSpeed,
                                divisions: _sliderDivisions,
                                label: speedValue.toStringAsFixed(1),
                                onChanged: (value) {
                                  controller.speed.value = value;
                                },
                              ),
                            ),
                          ),
                          const SizedBox(width: AppTheme.spacingSmall),
                          Text(
                            speedValue.toStringAsFixed(1),
                            style: textTheme.bodyMedium?.copyWith(
                              color: colorScheme.primary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
