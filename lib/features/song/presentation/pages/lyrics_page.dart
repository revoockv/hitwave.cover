import 'package:flutter/material.dart';
import 'package:watch_it/watch_it.dart';

import '../../../../core/domain/entities/result.dart';
import '../../../../core/domain/entities/result_state.dart';
import '../../../../core/presentation/theme.dart';
import '../../domain/entities/song.dart';
import '../controllers/lyrics_page_controller.dart';
import '../di/song_getters.dart';
import '../widgets/lyrics_controls_widget.dart';

/// Lyrics display page with auto-scroll functionality.
///
/// Shows the song title, author, and lyrics with a speed-controlled
/// auto-scroll feature. Controls auto-hide after inactivity.
final class LyricsPage extends WatchingWidget {
  /// Speed label text.
  static const String _speedLabel = 'Швидкість';

  /// Stop button label text.
  static const String _stopLabel = 'Пауза';

  /// Start button label text.
  static const String _startLabel = 'Старт';

  /// Font size for lyrics text.
  static const double _lyricsFontSize = 20;

  /// Bottom space so the last line can scroll above the control panel.
  static const double _controlsClearance = 120;

  /// Padding around the lyrics text while editing.
  static const EdgeInsets _lyricsPadding = EdgeInsets.fromLTRB(
    AppTheme.spacingLarge,
    AppTheme.spacingLarge,
    AppTheme.spacingLarge,
    _controlsClearance,
  );

  /// Part of the screen height left empty above the lyrics while scrolling,
  /// so there is time before the first lines move up.
  static const double _leadInFactor = 0.4;

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
    final bool isScrolling = watch(lyricsPageController.scrollingController).value;
    registerHandler(target: lyricsPageController.speedSavingStateController, handler: _onSpeedSavingChanged);
    final double leadIn = MediaQuery.sizeOf(context).height * _leadInFactor;

    final ThemeData theme = Theme.of(context);
    final TextStyle? lyricsStyle = theme.textTheme.bodyLarge?.copyWith(
      fontSize: _lyricsFontSize,
      height: AppTheme.readingLineHeight,
    );

    return Scaffold(
      appBar: AppBar(
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
                  child: isScrolling
                      ? SingleChildScrollView(
                          controller: lyricsPageController.lyricsScrollController,
                          padding: _lyricsPadding.copyWith(top: leadIn),
                          child: SizedBox(
                            width: double.infinity,
                            child: Text(lyricsPageController.lyricsTextController.text, style: lyricsStyle),
                          ),
                        )
                      : TextField(
                          controller: lyricsPageController.lyricsTextController,
                          focusNode: lyricsPageController.lyricsFocusNode,
                          scrollController: lyricsPageController.editScrollController,
                          textInputAction: TextInputAction.done,
                          onEditingComplete: lyricsPageController.hideKeyboard,
                          maxLines: null,
                          expands: true,
                          textAlignVertical: TextAlignVertical.top,
                          decoration: const InputDecoration(
                            filled: false,
                            border: InputBorder.none,
                            enabledBorder: InputBorder.none,
                            focusedBorder: InputBorder.none,
                            contentPadding: _lyricsPadding,
                          ),
                          style: lyricsStyle,
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
                  speedLabel: _speedLabel,
                  stopLabel: _stopLabel,
                  startLabel: _startLabel,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  LyricsPageController _createLyricsPageController() =>
      LyricsPageController(lyrics: song.lyrics, initialSpeed: song.scrollSpeed);

  static void _disposeLyricsPageController(LyricsPageController lyricsPageController) => lyricsPageController.dispose();

  /// Shows an error when the speed could not be saved.
  void _onSpeedSavingChanged(BuildContext context, ResultState<void> state, void Function() cancel) {
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
}
