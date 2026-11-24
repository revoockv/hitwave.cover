import 'dart:async';

import 'package:flutter/material.dart';

import '../../../../core/domain/entities/result_state.dart';
import '../../domain/entities/lyrics_layout.dart';
import '../../domain/entities/lyrics_chord.dart';
import '../../domain/entities/song_failure.dart';
import '../../domain/entities/tab_block.dart';
import 'lyrics_text_controller.dart';

/// UI state of the lyrics page, like a Flutter controller: auto-scroll, the
/// speed, the space above the lyrics, the controls visibility and the text field.
///
/// Knows nothing about use cases: the page saves the speed, the space and the
/// edited lyrics and records the outcomes in the `*SavingStateController` fields.
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

  /// Default space above the lyrics, as a part of the screen height.
  static const double _defaultLeadIn = 0.4;

  /// No space above the lyrics.
  static const double minLeadIn = 0.0;

  /// Largest space above the lyrics, as a part of the screen height.
  static const double maxLeadIn = 0.8;

  /// Current scroll speed (0.0 to 1.0).
  final ValueNotifier<double> speedController;

  /// Progress of saving the speed with the song; a failure is shown by the page.
  final ValueNotifier<ResultState<void, SongFailure>> speedSavingStateController =
      ValueNotifier<ResultState<void, SongFailure>>(ResultState.idle);

  /// Space above the lyrics before they scroll, as a part of the screen height.
  final ValueNotifier<double> leadInController;

  /// Progress of saving the space above the lyrics; a failure is shown by the page.
  final ValueNotifier<ResultState<void, SongFailure>> leadInSavingStateController =
      ValueNotifier<ResultState<void, SongFailure>>(ResultState.idle);

  /// Progress of saving the edited lyrics; a failure is shown by the page.
  final ValueNotifier<ResultState<void, SongFailure>> lyricsSavingStateController =
      ValueNotifier<ResultState<void, SongFailure>>(ResultState.idle);

  double _savedSpeed;

  double _savedLeadIn;

  String _savedLyrics;

  bool _isDisposed = false;

  /// Whether auto-scroll is currently running.
  final ValueNotifier<bool> scrollingController = ValueNotifier<bool>(false);

  /// Whether the controls bar is currently visible.
  final ValueNotifier<bool> controlsVisibilityController = ValueNotifier<bool>(true);

  /// Whether pressing start also records a take (the "record" checkbox).
  final ValueNotifier<bool> recordController;

  /// Whether the silence before and after the singing is cut from the enhanced take.
  final ValueNotifier<bool> trimSilenceController;

  /// Text of the lyrics field; draws its tablatures in a fixed-width font.
  final LyricsTextController lyricsTextController;

  /// Scroll position of the lyrics; kept on pause, moved by the user or by auto-scroll.
  final ScrollController lyricsScrollController = ScrollController();

  /// Focus of the lyrics text field.
  final FocusNode lyricsFocusNode = FocusNode();

  /// The screen the page was opened on: the speed and the space are saved for it.
  final LyricsLayout layout;

  /// Creates the controller with the [lyrics] to show on [layout], their [tabBlocks] and [chords].
  ///
  /// Starts at [initialSpeed] and [initialLeadIn] (saved with the song) or the defaults, with the
  /// checkboxes as they were last chosen ([record], [trimSilence]).
  LyricsPageController({
    required String lyrics,
    List<TabBlock> tabBlocks = const <TabBlock>[],
    List<LyricsChord> chords = const <LyricsChord>[],
    LyricsLayout layout = LyricsLayout.compact,
    double? initialSpeed,
    double? initialLeadIn,
    bool record = false,
    bool trimSilence = true,
  }) : this._(
         lyrics,
         tabBlocks,
         chords,
         (initialSpeed ?? _defaultSpeed).clamp(minSpeed, maxSpeed),
         (initialLeadIn ?? _defaultLeadIn).clamp(minLeadIn, maxLeadIn),
         record,
         trimSilence,
         layout,
       );

  LyricsPageController._(
    String lyrics,
    List<TabBlock> tabBlocks,
    List<LyricsChord> chords,
    double startSpeed,
    double startLeadIn,
    bool record,
    bool trimSilence,
    this.layout,
  ) : recordController = ValueNotifier<bool>(record),
      trimSilenceController = ValueNotifier<bool>(trimSilence),
      lyricsTextController = LyricsTextController(text: lyrics, tabBlocks: tabBlocks, chords: chords),
      speedController = ValueNotifier<double>(startSpeed),
      leadInController = ValueNotifier<double>(startLeadIn),
      _savedSpeed = startSpeed,
      _savedLeadIn = startLeadIn,
      _savedLyrics = lyrics;

  /// Whether a take is being started (the microphone opens): presses of the play button are
  /// ignored meanwhile, so a second press cannot stop or double the take being started.
  bool isStartingTake = false;

  /// Whether [dispose] was called; the owner checks it after every `await`.
  bool get isDisposed => _isDisposed;

  /// Whether a speed save may start: none is running and [speed] differs from the saved one.
  bool canSaveSpeed(double speed) => !speedSavingStateController.value.isLoading && speed != _savedSpeed;

  /// Remembers [speed] as the one saved with the song.
  void markSpeedSaved(double speed) {
    _savedSpeed = speed;
  }

  /// Whether a save of the space may start: none is running and [leadIn] differs from the saved one.
  bool canSaveLeadIn(double leadIn) => !leadInSavingStateController.value.isLoading && leadIn != _savedLeadIn;

  /// Remembers [leadIn] as the one saved with the song.
  void markLeadInSaved(double leadIn) {
    _savedLeadIn = leadIn;
  }

  /// Lyrics as typed in the field.
  String get lyrics => lyricsTextController.text;

  /// Whether the field holds lyrics that are not saved yet.
  bool get hasUnsavedLyrics => lyrics != _savedLyrics;

  /// Whether a save of the lyrics may start: none is running and the text changed.
  bool canSaveLyrics() => !lyricsSavingStateController.value.isLoading && hasUnsavedLyrics;

  /// Remembers [savedLyrics] as the lyrics saved with the song.
  void markLyricsSaved(String savedLyrics) {
    _savedLyrics = savedLyrics;
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
    if (!canStartScrolling) return;
    startScrolling();
  }

  /// Whether there are lyrics to scroll.
  bool get canStartScrolling => lyricsTextController.text.trim().isNotEmpty;

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
    leadInController.dispose();
    leadInSavingStateController.dispose();
    lyricsSavingStateController.dispose();
    scrollingController.dispose();
    controlsVisibilityController.dispose();
    recordController.dispose();
    trimSilenceController.dispose();
    lyricsTextController.dispose();
    lyricsScrollController.dispose();
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

  /// Starts auto-scrolling the lyrics text from where the view is now.
  ///
  /// Continues after a pause or from the place the user scrolled to; starts
  /// from the top again when the end was already reached. Scrolls by
  /// [_scrollIncrementMultiplier] times the speed every [_scrollIntervalMs] ms.
  void startScrolling() {
    if (scrollingController.value) return;

    if (lyricsScrollController.hasClients) {
      final ScrollPosition position = lyricsScrollController.position;
      if (position.pixels >= position.maxScrollExtent) lyricsScrollController.jumpTo(0);
    }
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

  /// Pauses auto-scrolling; the lyrics stay where they are.
  void stopScrolling() {
    scrollTimer?.cancel();
    scrollTimer = null;

    scrollingController.value = false;

    resetHideTimer();
  }
}
