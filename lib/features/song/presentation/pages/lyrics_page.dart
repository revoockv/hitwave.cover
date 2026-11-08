import 'package:flutter/material.dart';
import 'package:hitwave.cover/features/song/domain/entities/song.dart';
import 'package:hitwave.cover/features/song/presentation/controllers/lyrics_page_controller.dart';
import 'package:hitwave.cover/features/song/presentation/widgets/lyrics_controls_widget.dart';
import '../../../../core/presentation/theme.dart';

/// Lyrics display page with auto-scroll functionality.
///
/// Shows the song title, author, and lyrics with a speed-controlled
/// auto-scroll feature. Controls auto-hide after inactivity.
final class LyricsPage extends StatefulWidget {
  /// The song whose lyrics to display.
  final Song song;

  /// Creates a new [LyricsPage].
  const LyricsPage({required this.song, super.key});

  @override
  State<LyricsPage> createState() => _LyricsPageState();
}

class _LyricsPageState extends State<LyricsPage> {
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

  /// Padding around the lyrics text.
  static const EdgeInsets _lyricsPadding = EdgeInsets.fromLTRB(
    AppTheme.spacingLarge,
    AppTheme.spacingLarge,
    AppTheme.spacingLarge,
    _controlsClearance,
  );

  late final LyricsPageController _controller;

  @override
  void initState() {
    super.initState();
    _controller = LyricsPageController();
    _controller.initControllers(widget.song.lyrics);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _hideKeyboard() {
    if (_controller.focusNode.hasFocus) {
      _controller.focusNode.unfocus();
    }
  }

  void _startScrolling() {
    if (_controller.isScrolling.value) return;
    _controller.startScrolling(_resetHideTimer, _hideKeyboard);
  }

  void _stopScrolling() {
    _controller.stopScrolling(_resetHideTimer);
  }

  void _resetHideTimer() {
    _controller.resetHideTimer();
  }

  void _toggleScroll() {
    if (_controller.isScrolling.value) {
      _stopScrolling();
    } else {
      if (_controller.textController.text.trim().isEmpty) return;
      _startScrolling();
    }
  }

  void _onLyricsTapped() {
    _resetHideTimer();
    if (_controller.isScrolling.value) {
      FocusScope.of(context).unfocus();
    }
  }

  @override
  Widget build(BuildContext context) {
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
            Text(widget.song.name, maxLines: 1, overflow: TextOverflow.ellipsis),
            Text(
              widget.song.author,
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
              onTap: _onLyricsTapped,
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: AppTheme.maxContentWidth),
                  child: ValueListenableBuilder<bool>(
                    valueListenable: _controller.isScrolling,
                    builder: (BuildContext context, bool isScrolling, Widget? child) {
                      return isScrolling
                          ? SingleChildScrollView(
                              controller: _controller.scrollController,
                              padding: _lyricsPadding,
                              child: SizedBox(
                                width: double.infinity,
                                child: Text(_controller.textController.text, style: lyricsStyle),
                              ),
                            )
                          : TextField(
                              controller: _controller.textController,
                              focusNode: _controller.focusNode,
                              scrollController: _controller.editScrollController,
                              textInputAction: TextInputAction.done,
                              onEditingComplete: _hideKeyboard,
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
                            );
                    },
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
                  controller: _controller,
                  speedLabel: _speedLabel,
                  stopLabel: _stopLabel,
                  startLabel: _startLabel,
                  toggleScroll: _toggleScroll,
                  resetHideTimer: _resetHideTimer,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
