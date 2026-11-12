import 'dart:async';

import 'package:flutter/material.dart';
import 'package:watch_it/watch_it.dart';

import '../../../../core/domain/entities/result.dart';
import '../../../../core/domain/entities/result_state.dart';
import '../../../../core/presentation/theme.dart';
import '../../../history/presentation/di/history_getters.dart';
import '../../../practice/presentation/di/practice_getters.dart';
import '../../../recordings/domain/entities/recorder_state.dart';
import '../../../recordings/domain/entities/recording.dart';
import '../../../recordings/domain/entities/recording_preferences.dart';
import '../../../recordings/presentation/di/recordings_getters.dart';
import '../../../recordings/domain/entities/microphone.dart';
import '../../../recordings/presentation/widgets/microphone_picker_dialog_widget.dart';
import '../../../recordings/presentation/widgets/recordings_sheet_widget.dart';
import '../../domain/entities/song.dart';
import '../controllers/lyrics_page_controller.dart';
import '../di/song_getters.dart';
import '../widgets/lyrics_controls_widget.dart';

/// Lyrics display page with auto-scroll functionality.
///
/// Shows the song title, author, and lyrics with a speed-controlled
/// auto-scroll feature. Controls auto-hide after inactivity. The lyrics can be
/// edited in place: they are saved when the field loses focus (done, start of
/// scrolling) and when the page closes. The speed and the space above the
/// lyrics are saved with the song.
///
/// With "record" checked, start also records a take; the take goes on after
/// the lyrics end and stops only with the stop button or when the page closes,
/// then it is kept on the device and enhanced. The checkboxes are remembered.
/// The time between start and the end of both the scrolling and the take is
/// counted as practice. The recordings button opens the takes of this song.
final class LyricsPage extends WatchingWidget {
  /// Speed label text.
  static const String _speedLabel = 'Швидкість';

  /// Label of the space above the lyrics.
  static const String _leadInLabel = 'Відступ';

  /// Stop button label text.
  static const String _stopLabel = 'Пауза';

  /// Start button label text.
  static const String _startLabel = 'Старт';

  /// Label of the record checkbox.
  static const String _recordLabel = 'Запис';

  /// Label of the trim-silence checkbox.
  static const String _trimSilenceLabel = 'Обрізати тишу';

  /// Separator between the artist and the song in the name of a shared recording.
  static const String _shareSeparator = '-';

  /// Tooltip of the recordings button.
  static const String _recordingsLabel = 'Записи';

  /// Shown when a take was saved and its enhancement started.
  static const String _savedMessage = 'Запис збережено, покращую звук…';

  /// Shown when the microphone gave no sound during the take.
  static const String _silentMessage = 'Запис без звуку. Перевірте мікрофон (кнопка з мікрофоном на панелі).';

  /// Tooltip prefix of the microphone button.
  static const String _microphonePrefix = 'Мікрофон: ';

  /// Font size for lyrics text.
  static const double _lyricsFontSize = 20;

  /// Tooltip of the button while a take is being recorded.
  static const String _stopRecordingLabel = 'Зупинити запис';

  /// Space under the lyrics as a share of the screen height, so the last lines scroll up to the
  /// middle of the screen, well above the control panel.
  static const double _bottomSpaceFactor = 0.5;

  /// Padding around the lyrics; the top and the bottom are replaced by the page.
  static const EdgeInsets _lyricsPadding = EdgeInsets.symmetric(horizontal: AppTheme.spacingLarge);

  /// The song whose lyrics to display.
  final Song song;

  /// Creates a new [LyricsPage].
  const LyricsPage({required this.song, super.key});

  @override
  Widget build(BuildContext context) {
    final LyricsPageController lyricsPageController = createOnce(
      _createLyricsPageController,
      dispose: _disposeLyricsPageController,
    );
    callOnce(_onOpened);
    final bool isScrolling = watch(lyricsPageController.scrollingController).value;
    final double leadInFactor = watch(lyricsPageController.leadInController).value;
    registerHandler(target: lyricsPageController.speedSavingStateController, handler: _onSavingChanged);
    registerHandler(target: lyricsPageController.leadInSavingStateController, handler: _onSavingChanged);
    registerHandler(target: lyricsPageController.lyricsSavingStateController, handler: _onSavingChanged);
    registerHandler(
      target: lyricsPageController.recordController,
      handler: (BuildContext context, bool record, void Function() cancel) =>
          _onRecordingOptionsChanged(lyricsPageController),
    );
    registerHandler(
      target: lyricsPageController.trimSilenceController,
      handler: (BuildContext context, bool trimSilence, void Function() cancel) =>
          _onRecordingOptionsChanged(lyricsPageController),
    );
    registerHandler(
      target: lyricsPageController.scrollingController,
      handler: (BuildContext context, bool isScrolling, void Function() cancel) => _onScrollingChanged(isScrolling),
    );
    final RecorderState recorder = watch(watchRecorderUseCase()).value;
    final String? microphoneLabel = watch(watchRecordingPreferencesUseCase()).value.microphoneLabel;
    final int recordingCount = watch(
      watchRecordingsUseCase(),
    ).value.where((Recording recording) => recording.songId == song.id).length;
    final RecordingRecorderState? recording = recorder is RecordingRecorderState && recorder.songId == song.id
        ? recorder
        : null;
    final double screenHeight = MediaQuery.sizeOf(context).height;
    final double leadIn = screenHeight * leadInFactor;

    final ThemeData theme = Theme.of(context);
    final TextStyle? lyricsStyle = theme.textTheme.bodyLarge?.copyWith(
      fontSize: _lyricsFontSize,
      height: AppTheme.readingLineHeight,
    );

    return PopScope(
      onPopInvokedWithResult: (bool didPop, Object? result) => _onPagePopped(lyricsPageController),
      child: Scaffold(
        appBar: AppBar(
          actions: <Widget>[
            IconButton(
              tooltip: _recordingsLabel,
              onPressed: () => _openRecordings(context),
              icon: Badge(
                isLabelVisible: recordingCount > 0,
                label: Text('$recordingCount'),
                child: const Icon(Icons.library_music_outlined),
              ),
            ),
          ],
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(song.name, maxLines: 1, overflow: TextOverflow.ellipsis),
              Text(
                song.author,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
              ),
            ],
          ),
        ),
        body: Stack(
          children: <Widget>[
            Positioned.fill(
              child: GestureDetector(
                behavior: HitTestBehavior.translucent,
                onTap: lyricsPageController.onLyricsTapped,
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: AppTheme.maxContentWidth),
                    child: SingleChildScrollView(
                      controller: lyricsPageController.lyricsScrollController,
                      padding: _lyricsPadding.copyWith(top: leadIn, bottom: screenHeight * _bottomSpaceFactor),
                      child: IgnorePointer(
                        ignoring: isScrolling,
                        child: Focus(
                          onFocusChange: (bool hasFocus) => _onLyricsFocusChanged(lyricsPageController, hasFocus),
                          child: TextField(
                            controller: lyricsPageController.lyricsTextController,
                            focusNode: lyricsPageController.lyricsFocusNode,
                            readOnly: isScrolling,
                            textInputAction: TextInputAction.done,
                            onEditingComplete: lyricsPageController.hideKeyboard,
                            maxLines: null,
                            decoration: const InputDecoration(
                              filled: false,
                              border: InputBorder.none,
                              enabledBorder: InputBorder.none,
                              focusedBorder: InputBorder.none,
                              isCollapsed: true,
                            ),
                            style: lyricsStyle,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: AppTheme.maxContentWidth),
                  child: LyricsControlsWidget(
                    lyricsPageController: lyricsPageController,
                    onSpeedChosen: (double speed) => _onSpeedChosen(lyricsPageController, speed),
                    onLeadInChosen: (double leadIn) => _onLeadInChosen(lyricsPageController, leadIn),
                    speedLabel: _speedLabel,
                    leadInLabel: _leadInLabel,
                    stopLabel: _stopLabel,
                    startLabel: _startLabel,
                    stopRecordingLabel: _stopRecordingLabel,
                    recordLabel: _recordLabel,
                    trimSilenceLabel: _trimSilenceLabel,
                    onPlayPressed: () => _onPlayPressed(ScaffoldMessenger.of(context), lyricsPageController),
                    microphoneLabel:
                        '$_microphonePrefix${microphoneLabel ?? MicrophonePickerDialogWidget.systemMicrophone.label}',
                    onMicrophonePressed: () => _chooseMicrophone(context, ScaffoldMessenger.of(context)),
                    recordingElapsed: recording?.elapsed,
                    recordingLevel: recording?.level ?? 0,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  LyricsPageController _createLyricsPageController() {
    final RecordingPreferences preferences = watchRecordingPreferencesUseCase().value;
    return LyricsPageController(
      lyrics: song.lyrics,
      initialSpeed: song.scrollSpeed,
      initialLeadIn: song.leadIn,
      record: preferences.record,
      trimSilence: preferences.trimSilence,
    );
  }

  /// Remembers the opening for the recent songs of the home page.
  void _onOpened(BuildContext context) {
    unawaited(markSongOpenedUseCase(song.id));
  }

  static void _disposeLyricsPageController(LyricsPageController lyricsPageController) => lyricsPageController.dispose();

  /// Shows an error when the speed, the space or the lyrics could not be saved.
  void _onSavingChanged(BuildContext context, ResultState<void> state, void Function() cancel) {
    if (state is! FailureResultState<void>) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(state.message)));
  }

  /// Saves [speed] with this song when it changed; ignored while a save runs.
  Future<void> _onSpeedChosen(LyricsPageController lyricsPageController, double speed) async {
    if (!lyricsPageController.canSaveSpeed(speed)) return;
    final ValueNotifier<ResultState<void>> speedSavingStateController = lyricsPageController.speedSavingStateController;
    speedSavingStateController.value = ResultState.loading;

    final Result<void> result = await updateSongScrollSpeedUseCase(songId: song.id, speed: speed);
    if (lyricsPageController.isDisposed) return;

    if (result.isSuccess) lyricsPageController.markSpeedSaved(speed);
    speedSavingStateController.value = ResultState.of(result);
  }

  /// Saves the space above the lyrics ([leadIn]) with this song when it changed.
  Future<void> _onLeadInChosen(LyricsPageController lyricsPageController, double leadIn) async {
    if (!lyricsPageController.canSaveLeadIn(leadIn)) return;
    final ValueNotifier<ResultState<void>> leadInSavingStateController =
        lyricsPageController.leadInSavingStateController;
    leadInSavingStateController.value = ResultState.loading;

    final Result<void> result = await updateSongLeadInUseCase(songId: song.id, leadIn: leadIn);
    if (lyricsPageController.isDisposed) return;

    if (result.isSuccess) lyricsPageController.markLeadInSaved(leadIn);
    leadInSavingStateController.value = ResultState.of(result);
  }

  /// Saves the edited lyrics when the field loses focus.
  Future<void> _onLyricsFocusChanged(LyricsPageController lyricsPageController, bool hasFocus) async {
    if (hasFocus || !lyricsPageController.canSaveLyrics()) return;
    final ValueNotifier<ResultState<void>> lyricsSavingStateController =
        lyricsPageController.lyricsSavingStateController;
    final String lyrics = lyricsPageController.lyrics;
    lyricsSavingStateController.value = ResultState.loading;

    final Result<void> result = await updateSongLyricsUseCase(songId: song.id, lyrics: lyrics);
    if (lyricsPageController.isDisposed) return;

    if (result.isSuccess) lyricsPageController.markLyricsSaved(lyrics);
    lyricsSavingStateController.value = ResultState.of(result);
  }

  /// Saves the lyrics that are still unsaved when the page closes and stops a
  /// take that is being recorded; the page is gone by then, so nothing is shown.
  void _onPagePopped(LyricsPageController lyricsPageController) {
    if (watchRecorderUseCase().value is RecordingRecorderState) {
      unawaited(stopRecordingUseCase(trimSilence: lyricsPageController.trimSilenceController.value));
    }
    unawaited(stopPracticeUseCase());
    if (!lyricsPageController.hasUnsavedLyrics) return;
    unawaited(updateSongLyricsUseCase(songId: song.id, lyrics: lyricsPageController.lyrics));
  }

  /// Stops the take being recorded (and the scrolling), pauses, or starts scrolling — first
  /// starting a take when "record" is checked. The take goes on after the lyrics end: only this
  /// button or leaving the page stops it.
  Future<void> _onPlayPressed(ScaffoldMessengerState messenger, LyricsPageController lyricsPageController) async {
    final RecorderState recorder = watchRecorderUseCase().value;
    if (recorder is RecordingRecorderState && recorder.songId == song.id) {
      lyricsPageController.stopScrolling();
      await _stopTake(messenger, lyricsPageController);
      return;
    }
    if (lyricsPageController.scrollingController.value) {
      lyricsPageController.stopScrolling();
      return;
    }
    if (!lyricsPageController.canStartScrolling) return;
    if (lyricsPageController.recordController.value) {
      final Result<void> result = await startRecordingUseCase(
        song.id,
        microphoneId: watchRecordingPreferencesUseCase().value.microphoneId,
      );
      if (lyricsPageController.isDisposed) return;
      if (result case FailureResult<void>(:final String error)) {
        messenger.showSnackBar(SnackBar(content: Text(error)));
        return;
      }
    }
    unawaited(startPracticeUseCase(song.id));
    lyricsPageController.startScrolling();
  }

  /// Lets the user choose the sound input of the takes and remembers it.
  Future<void> _chooseMicrophone(BuildContext context, ScaffoldMessengerState messenger) async {
    final Result<List<Microphone>> listed = await listMicrophonesUseCase();
    if (!context.mounted) return;
    switch (listed) {
      case FailureResult<List<Microphone>>(:final String error):
        messenger.showSnackBar(SnackBar(content: Text(error)));
      case SuccessResult<List<Microphone>>(:final List<Microphone> value):
        final Microphone? chosen = await showDialog<Microphone>(
          context: context,
          builder: (BuildContext context) => MicrophonePickerDialogWidget(
            microphones: value,
            selectedId: watchRecordingPreferencesUseCase().value.microphoneId,
          ),
        );
        if (chosen == null) return;
        final bool isSystem = chosen.id == MicrophonePickerDialogWidget.systemMicrophone.id;
        await updateRecordingPreferencesUseCase(
          watchRecordingPreferencesUseCase().value.withMicrophone(
            id: isSystem ? null : chosen.id,
            label: isSystem ? null : chosen.label,
          ),
        );
    }
  }

  /// Remembers the checkboxes for the next visit.
  void _onRecordingOptionsChanged(LyricsPageController lyricsPageController) {
    unawaited(
      updateRecordingPreferencesUseCase(
        watchRecordingPreferencesUseCase().value.copyWith(
          record: lyricsPageController.recordController.value,
          trimSilence: lyricsPageController.trimSilenceController.value,
        ),
      ),
    );
  }

  /// Ends the practice session when the scrolling stops and no take is being recorded.
  void _onScrollingChanged(bool isScrolling) {
    if (isScrolling || watchRecorderUseCase().value is RecordingRecorderState) return;
    unawaited(stopPracticeUseCase());
  }

  /// Stops the take and tells whether it was saved.
  Future<void> _stopTake(ScaffoldMessengerState messenger, LyricsPageController lyricsPageController) async {
    final Result<Recording> result = await stopRecordingUseCase(
      trimSilence: lyricsPageController.trimSilenceController.value,
    );
    if (!lyricsPageController.scrollingController.value) unawaited(stopPracticeUseCase());
    messenger.showSnackBar(
      SnackBar(
        content: Text(result.when(success: _saved, failure: _identity)),
      ),
    );
  }

  /// Opens the recordings of this song; playback stops when the sheet closes.
  Future<void> _openRecordings(BuildContext context) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (BuildContext context) =>
          RecordingsSheetWidget(songId: song.id, shareName: '${song.author}$_shareSeparator${song.name}'),
    );
    await stopPlaybackUseCase();
  }

  static String _saved(Recording recording) => recording.isSilent ? _silentMessage : _savedMessage;

  static String _identity(String error) => error;
}
