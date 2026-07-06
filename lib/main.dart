import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  runApp(const HitwaveCoverApp());
}

class HitwaveCoverApp extends StatelessWidget {
  const HitwaveCoverApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: HitwaveCoverPage(),
    );
  }
}

class HitwaveCoverPage extends StatefulWidget {
  const HitwaveCoverPage({super.key});

  @override
  State<HitwaveCoverPage> createState() => _HitwaveCoverPageState();
}

class _HitwaveCoverPageState extends State<HitwaveCoverPage> {
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final ScrollController _editScrollController = ScrollController();
  final FocusNode _focusNode = FocusNode();

  Timer? _scrollTimer;
  Timer? _hideControlsTimer;

  double _speed = 0.5;
  bool _isScrolling = false;

  static const double _minSpeed = 0.0;
  static const double _maxSpeed = 1.0;
  static const int _scrollIntervalMs = 16;
  static const int _hideControlsDelayMs = 3000;

  bool _controlsVisible = true;

  @override
  void dispose() {
    _scrollTimer?.cancel();
    _hideControlsTimer?.cancel();
    _textController.dispose();
    _scrollController.dispose();
    _editScrollController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _resetHideTimer() {
    _hideControlsTimer?.cancel();
    setState(() {
      _controlsVisible = true;
    });
    _hideControlsTimer = Timer(
      const Duration(milliseconds: _hideControlsDelayMs),
      () {
        if (!_isScrolling || !mounted) return;
        setState(() {
          _controlsVisible = false;
        });
      },
    );
  }

  void _hideKeyboard() {
    if (_focusNode.hasFocus) {
      _focusNode.unfocus();
    }
  }

  void _startScrolling() {
    if (_isScrolling) return;

    setState(() {
      _isScrolling = true;
    });

    _hideKeyboard();
    _scrollTimer?.cancel();
    _scrollTimer = Timer.periodic(
      const Duration(milliseconds: _scrollIntervalMs),
      (_) {
        if (!_scrollController.hasClients) return;

        final maxScroll = _scrollController.position.maxScrollExtent;
        final currentScroll = _scrollController.offset;

        if (currentScroll >= maxScroll) {
          _stopScrolling();
          return;
        }

        final scrollIncrement = _speed * 0.3125;
        final newOffset = (currentScroll + scrollIncrement).clamp(
          0.0,
          maxScroll,
        );

        _scrollController.jumpTo(newOffset);
      },
    );

    _resetHideTimer();
  }

  void _stopScrolling() {
    _scrollTimer?.cancel();
    _scrollTimer = null;

    setState(() {
      _isScrolling = false;
    });

    _resetHideTimer();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_editScrollController.hasClients) {
        final maxScroll = _editScrollController.position.maxScrollExtent;
        if (maxScroll > 0) {
          _editScrollController.jumpTo(maxScroll);
        }
      }
    });
  }

  void _toggleScroll() {
    if (_isScrolling) {
      _stopScrolling();
    } else {
      if (_textController.text.trim().isEmpty) return;
      _startScrolling();
    }
  }

  Widget _buildControls() {
    return AnimatedOpacity(
      opacity: _controlsVisible ? 1.0 : 0.0,
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
                  value: _speed,
                  min: _minSpeed,
                  max: _maxSpeed,
                  divisions: 100,
                  label: _speed.toStringAsFixed(1),
                  onChanged: (value) {
                    setState(() {
                      _speed = value;
                    });
                    _hideKeyboard();
                    _resetHideTimer();
                  },
                ),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              _speed.toStringAsFixed(1),
              style: const TextStyle(color: Colors.white, fontSize: 16),
            ),
            const SizedBox(width: 16),
            ElevatedButton.icon(
              onPressed: _toggleScroll,
              icon: Icon(
                _isScrolling ? Icons.stop : Icons.play_arrow,
                color: Colors.black,
              ),
              label: Text(_isScrolling ? 'Зупинити' : 'Старт'),
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
      body: Column(
        children: [
          _buildControls(),
          Expanded(
            child: GestureDetector(
              onTap: () {
                if (_isScrolling) {
                  _resetHideTimer();
                  FocusScope.of(context).unfocus();
                } else {
                  _resetHideTimer();
                }
              },
              child: _isScrolling
                  ? SingleChildScrollView(
                      controller: _scrollController,
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Align(
                          alignment: Alignment.topLeft,
                          child: Text(
                            _textController.text,
                            style: Theme.of(context).textTheme.bodyLarge?.copyWith(fontSize: 18),
                          ),
                        ),
                      ),
                    )
                  : TextField(
                      controller: _textController,
                      focusNode: _focusNode,
                      scrollController: _editScrollController,
                      textInputAction: TextInputAction.done,
                      onEditingComplete: _hideKeyboard,
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
