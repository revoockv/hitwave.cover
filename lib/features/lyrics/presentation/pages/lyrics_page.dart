import 'dart:async';

import 'package:flutter/foundation.dart' show ValueListenable;
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
import '../../../recordings/domain/entities/shared_song.dart';
import '../../../recordings/presentation/di/recordings_getters.dart';
import '../../../recordings/domain/entities/microphone.dart';
import '../../../recordings/presentation/widgets/microphone_picker_dialog_widget.dart';
import '../../../recordings/presentation/pages/recordings_sheet_page.dart';
import '../../../song/domain/entities/lyrics_layout.dart';
import '../../../song/domain/entities/song.dart';
import '../controllers/lyrics_page_controller.dart';
import '../controllers/lyrics_text_controller.dart';
import '../../../song/domain/entities/lyrics_chord.dart';
import '../../../song/presentation/di/song_getters.dart';
import '../wrappers/lyrics_controls_wrapper.dart';
import '../wrappers/recording_indicator_wrapper.dart';
import '../../../../core/presentation/l10n/app_translations.dart';
import '../../../recordings/domain/entities/recordings_failure.dart';
import '../../../recordings/presentation/l10n/recordings_texts.dart';
import '../../../song/domain/entities/song_failure.dart';
import '../../../song/presentation/l10n/song_texts.dart';
import '../../../tuner/presentation/pages/tuner_page.dart';

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
/// With "practice" checked, the time between start and the end of both the
/// scrolling and the take is counted as practice; unchecked, the lyrics only scroll. The recordings button opens the takes of this song.
final class LyricsPage extends WatchingWidget {
  /// Font size for lyrics text.
  static const double _lyricsFontSize = 20;

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
    final Translations t = context.t;
    final LyricsLayout layout = MediaQuery.sizeOf(context).width >= AppTheme.railBreakpoint
        ? LyricsLayout.wide
        : LyricsLayout.compact;
    final LyricsPageController lyricsPageController = createOnce(
      () => _createLyricsPageController(layout),
      dispose: _disposeLyricsPageController,
    );
    // After the first frame: marking the song changes the history the home page watches, and
    // no other widget may be rebuilt while this one builds.
    callOnceAfterThisBuild(_onOpened);
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
      target: lyricsPageController.countPracticeController,
      handler: (BuildContext context, bool countPractice, void Function() cancel) =>
          _onRecordingOptionsChanged(lyricsPageController),
    );
    registerHandler(
      target: lyricsPageController.scrollingController,
      handler: (BuildContext context, bool isScrolling, void Function() cancel) => _onScrollingChanged(isScrolling),
    );
    // The recorder ticks several times a second: the page asks only whether this song is recorded.
    final bool isRecording = watchPropertyValue(_isRecordingOf, target: watchRecorderUseCase());
    final String? microphoneLabel = watchPropertyValue(_microphoneLabelOf, target: watchRecordingPreferencesUseCase());
    final int recordingCount = watchPropertyValue(_recordingCountOf, target: watchRecordingsUseCase());
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
              tooltip: t.tuner.open,
              // The microphone records the take: the tuner waits until the take ends.
              onPressed: isRecording ? null : () => _openTuner(context),
              icon: const Icon(Icons.graphic_eq),
            ),
            IconButton(
              tooltip: t.recordings.title,
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
                          child: LayoutBuilder(
                            builder: (BuildContext context, BoxConstraints constraints) => TextField(
                              controller: lyricsPageController.lyricsTextController..lineWidth = constraints.maxWidth,
                              onChanged: (String lyrics) => _onLyricsChanged(lyricsPageController, lyrics),
                              onTap: () =>
                                  _onLyricsFieldTapped(ScaffoldMessenger.of(context), context.t, lyricsPageController),
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
            ),
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: AppTheme.maxContentWidth),
                  child: LyricsControlsWrapper(
                    lyricsPageController: lyricsPageController,
                    onSpeedChosen: (double speed) => _onSpeedChosen(lyricsPageController, speed),
                    onLeadInChosen: (double leadIn) => _onLeadInChosen(lyricsPageController, leadIn),
                    speedLabel: t.song.speed,
                    leadInLabel: t.song.leadIn,
                    stopLabel: t.song.pause,
                    startLabel: t.song.start,
                    stopRecordingLabel: t.song.stopRecording,
                    recordLabel: t.song.record,
                    trimSilenceLabel: t.song.trimSilence,
                    countPracticeLabel: t.song.countPractice,
                    onPlayPressed: () => _onPlayPressed(ScaffoldMessenger.of(context), context.t, lyricsPageController),
                    microphoneLabel: t.song.microphone(name: microphoneLabel ?? t.recordings.systemMicrophone),
                    onMicrophonePressed: () => _chooseMicrophone(context, ScaffoldMessenger.of(context)),
                    isRecording: isRecording,
                    recordingIndicator: RecordingIndicatorWrapper(songId: song.id),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// The controller of the page opened on [layout], with the speed and the space saved for it.
  LyricsPageController _createLyricsPageController(LyricsLayout layout) {
    final RecordingPreferences preferences = watchRecordingPreferencesUseCase().value;
    return LyricsPageController(
      lyrics: song.lyrics,
      tabBlocks: song.tabs,
      chords: song.chords,
      layout: layout,
      initialSpeed: song.scrollSpeedOn(layout),
      initialLeadIn: song.leadInOn(layout),
      record: preferences.record,
      trimSilence: preferences.trimSilence,
      countPractice: preferences.countPractice,
    );
  }

  bool _isRecordingOf(ValueListenable<RecorderState> recorder) {
    final RecorderState state = recorder.value;
    return state is RecordingRecorderState && state.songId == song.id;
  }

  static String? _microphoneLabelOf(ValueListenable<RecordingPreferences> preferences) =>
      preferences.value.microphoneLabel;

  int _recordingCountOf(ValueListenable<List<Recording>> recordings) =>
      recordings.value.where((Recording recording) => recording.songId == song.id).length;

  /// Remembers the opening for the recent songs of the home page.
  void _onOpened(BuildContext context) {
    unawaited(markSongOpenedUseCase(song.id));
  }

  static void _disposeLyricsPageController(LyricsPageController lyricsPageController) => lyricsPageController.dispose();

  /// Shows an error when the speed, the space or the lyrics could not be saved.
  void _onSavingChanged(BuildContext context, ResultState<void, SongFailure> state, void Function() cancel) {
    if (state is! FailureResultState<void, SongFailure>) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(state.failure.text(context.t))));
  }

  /// Saves [speed] with this song when it changed; ignored while a save runs.
  Future<void> _onSpeedChosen(LyricsPageController lyricsPageController, double speed) async {
    if (!lyricsPageController.canSaveSpeed(speed)) return;
    final ValueNotifier<ResultState<void, SongFailure>> speedSavingStateController =
        lyricsPageController.speedSavingStateController;
    speedSavingStateController.value = ResultState.loading;

    final Result<void, SongFailure> result = await updateSongScrollSpeedUseCase(
      songId: song.id,
      layout: lyricsPageController.layout,
      speed: speed,
    );
    if (lyricsPageController.isDisposed) return;

    if (result.isSuccess) lyricsPageController.markSpeedSaved(speed);
    speedSavingStateController.value = ResultState.of(result);
  }

  /// Saves the space above the lyrics ([leadIn]) with this song when it changed.
  Future<void> _onLeadInChosen(LyricsPageController lyricsPageController, double leadIn) async {
    if (!lyricsPageController.canSaveLeadIn(leadIn)) return;
    final ValueNotifier<ResultState<void, SongFailure>> leadInSavingStateController =
        lyricsPageController.leadInSavingStateController;
    leadInSavingStateController.value = ResultState.loading;

    final Result<void, SongFailure> result = await updateSongLeadInUseCase(
      songId: song.id,
      layout: lyricsPageController.layout,
      leadIn: leadIn,
    );
    if (lyricsPageController.isDisposed) return;

    if (result.isSuccess) lyricsPageController.markLeadInSaved(leadIn);
    leadInSavingStateController.value = ResultState.of(result);
  }

  /// Finds the tablatures and chords of the edited [lyrics] again, so they keep their look.
  void _onLyricsChanged(LyricsPageController lyricsPageController, String lyrics) {
    lyricsPageController.lyricsTextController
      ..tabBlocks = findTabBlocksUseCase(lyrics)
      ..chords = findChordsUseCase(lyrics);
  }

  /// A tap on a chord offers to keep it as a word (`A girl` is no chord), a tap on such a word to make it a chord
  /// again.
  void _onLyricsFieldTapped(
    ScaffoldMessengerState messenger,
    Translations t,
    LyricsPageController lyricsPageController,
  ) {
    final LyricsTextController field = lyricsPageController.lyricsTextController;
    final int offset = field.selection.baseOffset;
    if (offset < 0) return;
    final String lyrics = field.text;
    final LyricsChord? chord = field.chords
        .where((LyricsChord chord) => chord.start <= offset && offset <= chord.end)
        .firstOrNull;
    if (chord != null) {
      _showChordChoice(
        messenger,
        text: t.song.chordTapped(chord: chord.text),
        action: t.song.makeWord,
        onPressed: () => _replaceLyrics(lyricsPageController, lyrics, markChordAsTextUseCase(lyrics, chord)),
      );
      return;
    }
    final ({int start, int end, String text})? word = findMarkedWordUseCase(lyrics, offset);
    if (word == null) return;
    _showChordChoice(
      messenger,
      text: t.song.wordTapped(word: word.text),
      action: t.song.makeChord,
      onPressed: () => _replaceLyrics(lyricsPageController, lyrics, unmarkChordUseCase(lyrics, word.start, word.end)),
    );
  }

  static void _showChordChoice(
    ScaffoldMessengerState messenger, {
    required String text,
    required String action,
    required VoidCallback onPressed,
  }) {
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(text),
          action: SnackBarAction(label: action, onPressed: onPressed),
        ),
      );
  }

  /// Puts [changed] in place of [before] (unless the lyrics were edited meanwhile), colours it and saves it.
  Future<void> _replaceLyrics(LyricsPageController lyricsPageController, String before, String changed) async {
    if (lyricsPageController.isDisposed) return;
    final LyricsTextController field = lyricsPageController.lyricsTextController;
    if (field.text != before) return;
    final int offset = field.selection.baseOffset.clamp(0, changed.length);
    field.value = TextEditingValue(
      text: changed,
      selection: TextSelection.collapsed(offset: offset),
    );
    _onLyricsChanged(lyricsPageController, changed);
    await _saveLyrics(lyricsPageController);
  }

  /// Saves the edited lyrics when the field loses focus.
  Future<void> _onLyricsFocusChanged(LyricsPageController lyricsPageController, bool hasFocus) async {
    if (hasFocus) return;
    await _saveLyrics(lyricsPageController);
  }

  /// Saves the lyrics in the field when they changed; ignored while a save runs.
  Future<void> _saveLyrics(LyricsPageController lyricsPageController) async {
    if (!lyricsPageController.canSaveLyrics()) return;
    final ValueNotifier<ResultState<void, SongFailure>> lyricsSavingStateController =
        lyricsPageController.lyricsSavingStateController;
    final String lyrics = lyricsPageController.lyrics;
    lyricsSavingStateController.value = ResultState.loading;

    final Result<void, SongFailure> result = await updateSongLyricsUseCase(songId: song.id, lyrics: lyrics);
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
  /// starting a take when "record" is checked, and the practice session when "practice" is. The take goes on after the lyrics end: only this
  /// button or leaving the page stops it.
  Future<void> _onPlayPressed(
    ScaffoldMessengerState messenger,
    Translations t,
    LyricsPageController lyricsPageController,
  ) async {
    if (lyricsPageController.isStartingTake) return;
    final RecorderState recorder = watchRecorderUseCase().value;
    if (recorder is RecordingRecorderState && recorder.songId == song.id) {
      lyricsPageController.stopScrolling();
      await _stopTake(messenger, t, lyricsPageController);
      return;
    }
    if (lyricsPageController.scrollingController.value) {
      lyricsPageController.stopScrolling();
      return;
    }
    if (!lyricsPageController.canStartScrolling) return;
    if (lyricsPageController.recordController.value) {
      lyricsPageController.isStartingTake = true;
      final Result<void, RecordingsFailure> result = await startRecordingUseCase(
        song.id,
        microphoneId: watchRecordingPreferencesUseCase().value.microphoneId,
      );
      if (lyricsPageController.isDisposed) return;
      lyricsPageController.isStartingTake = false;
      if (result case FailureResult<void, RecordingsFailure>(:final RecordingsFailure failure)) {
        messenger.showSnackBar(SnackBar(content: Text(failure.text(t))));
        return;
      }
    }
    if (lyricsPageController.countPracticeController.value) unawaited(startPracticeUseCase(song.id));
    lyricsPageController.startScrolling();
  }

  /// Lets the user choose the sound input of the takes and remembers it.
  Future<void> _chooseMicrophone(BuildContext context, ScaffoldMessengerState messenger) async {
    final Result<List<Microphone>, RecordingsFailure> listed = await listMicrophonesUseCase();
    if (!context.mounted) return;
    switch (listed) {
      case FailureResult<List<Microphone>, RecordingsFailure>(:final RecordingsFailure failure):
        messenger.showSnackBar(SnackBar(content: Text(failure.text(context.t))));
      case SuccessResult<List<Microphone>, RecordingsFailure>(:final List<Microphone> value):
        final Microphone? chosen = await showDialog<Microphone>(
          context: context,
          builder: (BuildContext context) => MicrophonePickerDialogWidget(
            microphones: value,
            selectedId: watchRecordingPreferencesUseCase().value.microphoneId,
            texts: context.t.recordingsTexts,
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
          countPractice: lyricsPageController.countPracticeController.value,
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
  Future<void> _stopTake(
    ScaffoldMessengerState messenger,
    Translations t,
    LyricsPageController lyricsPageController,
  ) async {
    final Result<Recording, RecordingsFailure> result = await stopRecordingUseCase(
      trimSilence: lyricsPageController.trimSilenceController.value,
    );
    if (!lyricsPageController.scrollingController.value) unawaited(stopPracticeUseCase());
    messenger.showSnackBar(
      SnackBar(
        content: Text(
          result.when(
            success: (Recording recording) => _saved(t, recording),
            failure: (RecordingsFailure failure) => failure.text(t),
          ),
        ),
      ),
    );
  }

  /// Opens the tuner; it frees the microphone when its page closes.
  Future<void> _openTuner(BuildContext context) async {
    await Navigator.of(context).push(MaterialPageRoute<void>(builder: (BuildContext context) => const TunerPage()));
  }

  /// Opens the recordings of this song; playback stops when the sheet closes.
  Future<void> _openRecordings(BuildContext context) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (BuildContext context) => RecordingsSheetPage(
        songId: song.id,
        song: SharedSong(author: song.author, name: song.name),
      ),
    );
    await stopPlaybackUseCase();
  }

  static String _saved(Translations t, Recording recording) =>
      recording.isSilent ? t.song.silentTake : t.song.takeSaved;
}
