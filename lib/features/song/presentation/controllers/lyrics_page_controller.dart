import 'dart:async';

import 'package:flutter/material.dart';

/// Controller for lyrics page reactive state.
///
/// Exposes [speed], [isScrolling], and [controlsVisible] as [ValueNotifier]
/// fields so the UI can reactively update via [ValueListenableBuilder].
/// Also owns the [textController], [scrollController], [editScrollController],
/// and [focusNode] so the UI layer has no stateful elements.
final class LyricsPageController {
  /// Default scroll speed.
  static const double _defaultSpeed = 0.5;

  /// Scroll interval in milliseconds.
  static const int _scrollIntervalMs = 16;

  /// Controls auto-hide delay in milliseconds.
  static const int _hideControlsDelayMs = 3000;

  /// Scroll increment multiplier.
  static const double _scrollIncrementMultiplier = 0.3125;

  /// Current scroll speed (0.0 to 1.0).
  final ValueNotifier<double> speed = ValueNotifier(_defaultSpeed);

  /// Whether auto-scroll is currently active.
  final ValueNotifier<bool> isScrolling = ValueNotifier(false);

  /// Whether the controls bar is currently visible.
  final ValueNotifier<bool> controlsVisible = ValueNotifier(true);

  /// Controller for the lyrics text field.
  final TextEditingController textController;

  /// Controller for the auto-scrolling lyrics view.
  final ScrollController scrollController = ScrollController();

  /// Controller for the edit-mode lyrics view.
  final ScrollController editScrollController = ScrollController();

  /// Focus node for the lyrics text field.
  final FocusNode focusNode = FocusNode();

  /// Creates the controller with the [lyrics] to show.
  LyricsPageController({required String lyrics}) : textController = TextEditingController(text: lyrics);

  /// Hides the keyboard of the lyrics field.
  void hideKeyboard() {
    if (focusNode.hasFocus) {
      focusNode.unfocus();
    }
  }

  /// Starts auto-scrolling, or stops it when it runs; nothing to scroll in empty lyrics.
  void toggleScroll() {
    if (isScrolling.value) {
      stopScrolling();
      return;
    }
    if (textController.text.trim().isEmpty) return;
    startScrolling();
  }

  /// Shows the controls again after a tap on the lyrics.
  void onLyricsTapped() {
    resetHideTimer();
    if (isScrolling.value) {
      hideKeyboard();
    }
  }

  /// Cancels all timers and disposes all [ValueNotifier] and controller fields.
  void dispose() {
    scrollTimer?.cancel();
    hideControlsTimer?.cancel();
    speed.dispose();
    isScrolling.dispose();
    controlsVisible.dispose();
    textController.dispose();
    scrollController.dispose();
    editScrollController.dispose();
    focusNode.dispose();
  }

  /// Timer that advances the auto-scroll; `null` while not scrolling.
  Timer? scrollTimer;

  /// Timer that hides the controls after inactivity.
  Timer? hideControlsTimer;

  /// Resets the controls auto-hide timer.
  ///
  /// Makes controls visible immediately, then schedules them to auto-hide
  /// after [_hideControlsDelayMs] milliseconds of inactivity.
  void resetHideTimer() {
    hideControlsTimer?.cancel();
    controlsVisible.value = true;
    hideControlsTimer = Timer(const Duration(milliseconds: _hideControlsDelayMs), () {
      if (!isScrolling.value || !controlsVisible.value) return;
      controlsVisible.value = false;
    });
  }

  /// Starts auto-scrolling the lyrics text.
  ///
  /// Cancels any existing scroll timer, sets [isScrolling] to true,
  /// and starts a periodic timer that scrolls by [_scrollIncrementMultiplier]
  /// every [_scrollIntervalMs] milliseconds.
  void startScrolling() {
    if (isScrolling.value) return;

    isScrolling.value = true;
    hideKeyboard();
    scrollTimer?.cancel();
    scrollTimer = Timer.periodic(const Duration(milliseconds: _scrollIntervalMs), (_) {
      if (!scrollController.hasClients) return;

      final maxScroll = scrollController.position.maxScrollExtent;
      final currentScroll = scrollController.offset;

      if (currentScroll >= maxScroll) {
        stopScrolling();
        return;
      }

      final scrollIncrement = speed.value * _scrollIncrementMultiplier;
      final newOffset = (currentScroll + scrollIncrement).clamp(0.0, maxScroll);

      scrollController.jumpTo(newOffset);
    });

    resetHideTimer();
  }

  /// Stops auto-scrolling and scrolls to the bottom of the lyrics.
  void stopScrolling() {
    scrollTimer?.cancel();
    scrollTimer = null;

    isScrolling.value = false;

    resetHideTimer();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (editScrollController.hasClients) {
        final maxScroll = editScrollController.position.maxScrollExtent;
        if (maxScroll > 0) {
          editScrollController.jumpTo(maxScroll);
        }
      }
    });
  }
}
