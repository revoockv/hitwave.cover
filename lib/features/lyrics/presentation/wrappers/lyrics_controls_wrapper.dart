import 'package:flutter/material.dart';
import 'package:watch_it/watch_it.dart';

import '../controllers/lyrics_page_controller.dart';
import '../widgets/lyrics_controls_widget.dart';

/// Gives [LyricsControlsWidget] the values of the page's [LyricsPageController] and moves them when the user does;
/// every move shows the panel again for a while.
final class LyricsControlsWrapper extends WatchingWidget {
  /// UI state of the lyrics page, owned by the page.
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

  /// Tooltip of the microphone button (the chosen input).
  final String microphoneLabel;

  /// Called by the microphone button.
  final VoidCallback onMicrophonePressed;

  /// Whether a take of this song is being recorded.
  final bool isRecording;

  /// Shows the time and the level of the take; its wrapper watches the recorder.
  final Widget recordingIndicator;

  /// Creates the wrapper.
  const LyricsControlsWrapper({
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
    required this.microphoneLabel,
    required this.onMicrophonePressed,
    required this.isRecording,
    required this.recordingIndicator,
  });

  @override
  Widget build(BuildContext context) {
    final bool visible = watch(lyricsPageController.controlsVisibilityController).value;
    final bool isScrolling = watch(lyricsPageController.scrollingController).value;
    final double speed = watch(lyricsPageController.speedController).value;
    final double leadIn = watch(lyricsPageController.leadInController).value;
    final bool record = watch(lyricsPageController.recordController).value;
    final bool trimSilence = watch(lyricsPageController.trimSilenceController).value;
    return LyricsControlsWidget(
      visible: visible,
      isScrolling: isScrolling,
      speed: speed,
      minSpeed: LyricsPageController.minSpeed,
      maxSpeed: LyricsPageController.maxSpeed,
      leadIn: leadIn,
      minLeadIn: LyricsPageController.minLeadIn,
      maxLeadIn: LyricsPageController.maxLeadIn,
      record: record,
      trimSilence: trimSilence,
      onSpeedChanged: _onSpeedChanged,
      onLeadInChanged: _onLeadInChanged,
      onRecordChanged: _onRecordChanged,
      onTrimSilenceChanged: _onTrimSilenceChanged,
      onSpeedChosen: onSpeedChosen,
      onLeadInChosen: onLeadInChosen,
      leadInLabel: leadInLabel,
      speedLabel: speedLabel,
      stopLabel: stopLabel,
      startLabel: startLabel,
      stopRecordingLabel: stopRecordingLabel,
      recordLabel: recordLabel,
      trimSilenceLabel: trimSilenceLabel,
      onPlayPressed: onPlayPressed,
      microphoneLabel: microphoneLabel,
      onMicrophonePressed: onMicrophonePressed,
      isRecording: isRecording,
      recordingIndicator: recordingIndicator,
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

  void _onRecordChanged(bool value) {
    lyricsPageController.recordController.value = value;
    lyricsPageController.resetHideTimer();
  }

  void _onTrimSilenceChanged(bool value) {
    lyricsPageController.trimSilenceController.value = value;
    lyricsPageController.resetHideTimer();
  }
}
