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
  late final TextEditingController textController;

  /// Controller for the auto-scrolling lyrics view.
  late final ScrollController scrollController;

  /// Controller for the edit-mode lyrics view.
  late final ScrollController editScrollController;

  /// Focus node for the lyrics text field.
  late final FocusNode focusNode;

  /// Initializes the text and scroll controllers with the given lyrics.
  void initControllers(String lyrics) {
    textController = TextEditingController(text: lyrics);
    scrollController = ScrollController();
    editScrollController = ScrollController();
    focusNode = FocusNode();
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
    hideControlsTimer = Timer(
      const Duration(milliseconds: _hideControlsDelayMs),
      () {
        if (!isScrolling.value || !controlsVisible.value) return;
        controlsVisible.value = false;
      },
    );
  }

  /// Starts auto-scrolling the lyrics text.
  ///
  /// Cancels any existing scroll timer, sets [isScrolling] to true,
  /// and starts a periodic timer that scrolls by [_scrollIncrementMultiplier]
  /// every [_scrollIntervalMs] milliseconds.
  void startScrolling(
    void Function() resetHideTimer,
    void Function() hideKeyboard,
  ) {
    if (isScrolling.value) return;

    isScrolling.value = true;
    hideKeyboard();
    scrollTimer?.cancel();
    scrollTimer = Timer.periodic(
      const Duration(milliseconds: _scrollIntervalMs),
      (_) {
        if (!scrollController.hasClients) return;

        final maxScroll = scrollController.position.maxScrollExtent;
        final currentScroll = scrollController.offset;

        if (currentScroll >= maxScroll) {
          stopScrolling(resetHideTimer);
          return;
        }

        final scrollIncrement = speed.value * _scrollIncrementMultiplier;
        final newOffset = (currentScroll + scrollIncrement).clamp(
          0.0,
          maxScroll,
        );

        scrollController.jumpTo(newOffset);
      },
    );

    resetHideTimer();
  }

  /// Stops auto-scrolling and scrolls to the bottom of the lyrics.
  void stopScrolling(void Function() resetHideTimer) {
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

  /// Toggles auto-scrolling on or off.
  bool toggleScroll(String lyricsText) {
    if (isScrolling.value) {
      return false;
    }
    if (lyricsText.trim().isEmpty) return false;
    return true;
  }
}
