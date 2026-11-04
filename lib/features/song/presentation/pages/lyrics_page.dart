
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
  static const String _stopLabel = 'Зупинити';

  /// Start button label text.
  static const String _startLabel = 'Старт';

  /// Font family for lyrics text.
  static const String _robotoFontFamily = 'Roboto';

  /// Font size for lyrics text.
  static const double _lyricsFontSize = 18;

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.song.name),
            Text(
              widget.song.author,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () {
                if (_controller.isScrolling.value) {
                  _resetHideTimer();
                  FocusScope.of(context).unfocus();
                } else {
                  _resetHideTimer();
                }
              },
              child: ValueListenableBuilder<bool>(
                valueListenable: _controller.isScrolling,
                builder: (context, isScrollingValue, child) {
                  return isScrollingValue
                      ? SingleChildScrollView(
                          controller: _controller.scrollController,
                          child: Padding(
                            padding: const EdgeInsets.all(AppTheme.spacingLarge),
                            child: Align(
                              alignment: Alignment.topLeft,
                              child: Text(
                                _controller.textController.text,
                                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                      fontSize: _lyricsFontSize,
                                    ),
                              ),
                            ),
                          ),
                        )
                      : TextField(
                          controller: _controller.textController,
                          focusNode: _controller.focusNode,
                          scrollController: _controller.editScrollController,
                          textInputAction: TextInputAction.done,
                          onEditingComplete: _hideKeyboard,
                          maxLines: null,
                          minLines: 1,
                          decoration: const InputDecoration(
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.all(AppTheme.spacingLarge),
                          ),
                          style: const TextStyle(fontSize: _lyricsFontSize, fontFamily: _robotoFontFamily),
                        );
                },
              ),
            ),
          ),
          LyricsControlsWidget(
            controller: _controller,
            speedLabel: _speedLabel,
            stopLabel: _stopLabel,
            startLabel: _startLabel,
            toggleScroll: _toggleScroll,
            resetHideTimer: _resetHideTimer,
          ),
        ],
      ),
    );
  }
}
