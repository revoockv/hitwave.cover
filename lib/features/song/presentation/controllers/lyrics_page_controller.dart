import 'dart:async';

import 'package:flutter/material.dart';

import '../../../../core/domain/entities/result_state.dart';

/// UI state of the lyrics page, like a Flutter controller: auto-scroll, the
/// speed, the controls visibility and the text field.
///
/// Knows nothing about use cases: the page saves the chosen speed and records
/// the outcome in [speedSavingStateController].
final class LyricsPageController {
  /// Default scroll speed.
  static const double _defaultSpeed = 0.5;

  /// Scroll interval in milliseconds.
  static const int _scrollIntervalMs = 16;

  /// Controls auto-hide delay in milliseconds.
  static const int _hideControlsDelayMs = 3000;

  /// Scroll increment multiplier.
  static const double _scrollIncrementMultiplier = 0.3125;

  /// Lowest scroll speed.
  static const double minSpeed = 0.0;

  /// Highest scroll speed.
  static const double maxSpeed = 1.0;

  /// Current scroll speed (0.0 to 1.0).
  final ValueNotifier<double> speedController;

  /// Progress of saving the speed with the song; a failure is shown by the page.
  final ValueNotifier<ResultState<void>> speedSavingStateController = ValueNotifier<ResultState<void>>(
    ResultState.idle,
  );

  double _savedSpeed;

  bool _isDisposed = false;

  /// Whether auto-scroll is currently running.
  final ValueNotifier<bool> scrollingController = ValueNotifier<bool>(false);

  /// Whether the controls bar is currently visible.
  final ValueNotifier<bool> controlsVisibilityController = ValueNotifier<bool>(true);

  /// Text of the lyrics field.
  final TextEditingController lyricsTextController;

  /// Scroll position of the auto-scrolling lyrics view.
  final ScrollController lyricsScrollController = ScrollController();

  /// Scroll position of the edit-mode lyrics view.
  final ScrollController editScrollController = ScrollController();

  /// Focus of the lyrics text field.
  final FocusNode lyricsFocusNode = FocusNode();

  /// Creates the controller with the [lyrics] to show.
  ///
  /// Starts at [initialSpeed] (the speed saved with the song) or the default.
  LyricsPageController({required String lyrics, double? initialSpeed})
    : this._(lyrics, (initialSpeed ?? _defaultSpeed).clamp(minSpeed, maxSpeed));

  LyricsPageController._(String lyrics, double startSpeed)
    : lyricsTextController = TextEditingController(text: lyrics),
      speedController = ValueNotifier<double>(startSpeed),
      _savedSpeed = startSpeed;

  /// Whether [dispose] was called; the owner checks it after every `await`.
  bool get isDisposed => _isDisposed;

  /// Whether a speed save may start: none is running and [speed] differs from the saved one.
  bool canSaveSpeed(double speed) => !speedSavingStateController.value.isLoading && speed != _savedSpeed;

  /// Remembers [speed] as the one saved with the song.
  void markSpeedSaved(double speed) {
    _savedSpeed = speed;
  }

  /// Hides the keyboard of the lyrics field.
  void hideKeyboard() {
    if (lyricsFocusNode.hasFocus) {
      lyricsFocusNode.unfocus();
    }
  }

  /// Starts auto-scrolling, or stops it when it runs; nothing to scroll in empty lyrics.
  void toggleScroll() {
    if (scrollingController.value) {
      stopScrolling();
      return;
    }
    if (lyricsTextController.text.trim().isEmpty) return;
    startScrolling();
  }

  /// Shows the controls again after a tap on the lyrics.
  void onLyricsTapped() {
    resetHideTimer();
    if (scrollingController.value) {
      hideKeyboard();
    }
  }

  /// Cancels all timers and disposes all [ValueNotifier] and controller fields.
  void dispose() {
    scrollTimer?.cancel();
    hideControlsTimer?.cancel();
    _isDisposed = true;
    speedController.dispose();
    speedSavingStateController.dispose();
    scrollingController.dispose();
    controlsVisibilityController.dispose();
    lyricsTextController.dispose();
    lyricsScrollController.dispose();
    editScrollController.dispose();
    lyricsFocusNode.dispose();
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
    controlsVisibilityController.value = true;
    hideControlsTimer = Timer(const Duration(milliseconds: _hideControlsDelayMs), () {
      if (!scrollingController.value || !controlsVisibilityController.value) return;
      controlsVisibilityController.value = false;
    });
  }

  /// Starts auto-scrolling the lyrics text.
  ///
  /// Cancels any existing scroll timer, sets [scrollingController] to true,
  /// and starts a periodic timer that scrolls by [_scrollIncrementMultiplier]
  /// every [_scrollIntervalMs] milliseconds.
  void startScrolling() {
    if (scrollingController.value) return;

    scrollingController.value = true;
    hideKeyboard();
    scrollTimer?.cancel();
    scrollTimer = Timer.periodic(const Duration(milliseconds: _scrollIntervalMs), (_) {
      if (!lyricsScrollController.hasClients) return;

      final maxScroll = lyricsScrollController.position.maxScrollExtent;
      final currentScroll = lyricsScrollController.offset;

      if (currentScroll >= maxScroll) {
        stopScrolling();
        return;
      }

      final scrollIncrement = speedController.value * _scrollIncrementMultiplier;
      final newOffset = (currentScroll + scrollIncrement).clamp(0.0, maxScroll);

      lyricsScrollController.jumpTo(newOffset);
    });

    resetHideTimer();
  }

  /// Stops auto-scrolling and scrolls to the bottom of the lyrics.
  void stopScrolling() {
    scrollTimer?.cancel();
    scrollTimer = null;

    scrollingController.value = false;

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
