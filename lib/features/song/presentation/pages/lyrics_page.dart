import 'dart:async';

import 'package:flutter/material.dart';
import 'package:hitwave.cover/features/song/domain/entities/song.dart';

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
  late final TextEditingController textController;
  late final ScrollController scrollController;
  late final ScrollController editScrollController;
  late final FocusNode focusNode;

  Timer? scrollTimer;
  Timer? hideControlsTimer;

  double speed = 0.5;
  bool isScrolling = false;

  static const double minSpeed = 0.0;
  static const double maxSpeed = 1.0;
  static const int scrollIntervalMs = 16;
  static const int hideControlsDelayMs = 3000;

  bool controlsVisible = true;

  @override
  void initState() {
    super.initState();
    textController = TextEditingController(text: widget.song.lyrics);
    scrollController = ScrollController();
    editScrollController = ScrollController();
    focusNode = FocusNode();
  }

  @override
  void dispose() {
    scrollTimer?.cancel();
    hideControlsTimer?.cancel();
    textController.dispose();
    scrollController.dispose();
    editScrollController.dispose();
    focusNode.dispose();
    super.dispose();
  }

  void resetHideTimer() {
    hideControlsTimer?.cancel();
    setState(() {
      controlsVisible = true;
    });
    hideControlsTimer = Timer(
      const Duration(milliseconds: hideControlsDelayMs),
      () {
        if (!isScrolling || !mounted) return;
        setState(() {
          controlsVisible = false;
        });
      },
    );
  }

  void hideKeyboard() {
    if (focusNode.hasFocus) {
      focusNode.unfocus();
    }
  }

  void startScrolling() {
    if (isScrolling) return;

    setState(() {
      isScrolling = true;
    });

    hideKeyboard();
    scrollTimer?.cancel();
    scrollTimer = Timer.periodic(
      const Duration(milliseconds: scrollIntervalMs),
      (_) {
        if (!scrollController.hasClients) return;

        final maxScroll = scrollController.position.maxScrollExtent;
        final currentScroll = scrollController.offset;

        if (currentScroll >= maxScroll) {
          stopScrolling();
          return;
        }

        final scrollIncrement = speed * 0.3125;
        final newOffset = (currentScroll + scrollIncrement).clamp(
          0.0,
          maxScroll,
        );

        scrollController.jumpTo(newOffset);
      },
    );

    resetHideTimer();
  }

  void stopScrolling() {
    scrollTimer?.cancel();
    scrollTimer = null;

    setState(() {
      isScrolling = false;
    });

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

  void toggleScroll() {
    if (isScrolling) {
      stopScrolling();
    } else {
      if (textController.text.trim().isEmpty) return;
      startScrolling();
    }
  }

  Widget buildControls() {
    return AnimatedOpacity(
      opacity: controlsVisible ? 1.0 : 0.0,
      duration: const Duration(milliseconds: 300),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.7),
          borderRadius: const BorderRadius.vertical(
            bottom: Radius.circular(16),
          ),
        ),
        child: Row(
          children: [
            const SizedBox(width: 8),
            const Text(
              'Швидкість',
              style: TextStyle(color: Colors.white, fontSize: 14),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: SliderTheme(
                data: const SliderThemeData(
                  thumbColor: Colors.white,
                  trackHeight: 4,
                ),
                child: Slider(
                  value: speed,
                  min: minSpeed,
                  max: maxSpeed,
                  divisions: 100,
                  label: speed.toStringAsFixed(1),
                  onChanged: (value) {
                    setState(() {
                      speed = value;
                    });
                    hideKeyboard();
                    resetHideTimer();
                  },
                ),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              speed.toStringAsFixed(1),
              style: const TextStyle(color: Colors.white, fontSize: 16),
            ),
            const SizedBox(width: 16),
            ElevatedButton.icon(
              onPressed: toggleScroll,
              icon: Icon(
                isScrolling ? Icons.stop : Icons.play_arrow,
                color: Colors.black,
              ),
              label: Text(isScrolling ? 'Зупинити' : 'Старт'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: Colors.black,
              ),
            ),
            const SizedBox(width: 16),
          ],
        ),
      ),
    );
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
          buildControls(),
          Expanded(
            child: GestureDetector(
              onTap: () {
                if (isScrolling) {
                  resetHideTimer();
                  FocusScope.of(context).unfocus();
                } else {
                  resetHideTimer();
                }
              },
              child: isScrolling
                  ? SingleChildScrollView(
                      controller: scrollController,
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Align(
                          alignment: Alignment.topLeft,
                          child: Text(
                            textController.text,
                            style: Theme.of(context).textTheme.bodyLarge?.copyWith(fontSize: 18),
                          ),
                        ),
                      ),
                    )
                  : TextField(
                      controller: textController,
                      focusNode: focusNode,
                      scrollController: editScrollController,
                      textInputAction: TextInputAction.done,
                      onEditingComplete: hideKeyboard,
                      maxLines: null,
                      minLines: 1,
                      decoration: const InputDecoration(
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.all(24),
                      ),
                      style: const TextStyle(fontSize: 18, fontFamily: 'Roboto'),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}
