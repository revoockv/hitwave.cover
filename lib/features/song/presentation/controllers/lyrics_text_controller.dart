import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../domain/entities/lyrics_chord.dart';
import '../../domain/entities/tab_block.dart';

/// Text of the lyrics field that draws the chords in the accent colour and the tablatures in a
/// fixed-width font, so their strings keep their columns; a tab wider than the field is made
/// smaller to fit it on one line.
///
/// UI state only: the owner widget finds the tabs and chords with the use cases and gives them
/// to [tabBlocks] and [chords]; the layout gives the field's width to [lineWidth].
final class LyricsTextController extends TextEditingController {
  /// Fixed-width font of the tabs, bundled with the app (`assets/fonts`), so every platform draws the same.
  static const String _monospaceFamily = 'RobotoMono';

  /// Line height of a tab: the strings sit close, so the tab reads as one picture.
  static const double _tabLineHeight = 1.25;

  /// Smallest font of a tab; a tab that still does not fit wraps.
  static const double _minTabFontSize = 7;

  /// Font size a character width is measured at.
  static const double _measureFontSize = 100;

  /// Room left for the cursor and rounding, so a fitted line never wraps.
  static const double _widthReserve = 4;

  static const String _measureCharacter = '0';

  /// Size of the text the lyrics use when the style gives none (Flutter's default).
  static const double _defaultFontSize = 14;

  /// Tab blocks of the current text, in order; the owner updates them when the text changes.
  List<TabBlock> tabBlocks;

  /// Chords of the current text, in order; the owner updates them when the text changes.
  List<LyricsChord> chords;

  /// Width of the field, set by its layout; `null` until it is laid out (tabs then keep their size).
  double? lineWidth;

  /// Width of one character of the fixed-width font at [_measureFontSize], per text scaler.
  double? _characterWidth;
  TextScaler? _measuredScaler;

  /// Creates the controller with [text], its [tabBlocks] and [chords].
  LyricsTextController({super.text, this.tabBlocks = const <TabBlock>[], this.chords = const <LyricsChord>[]});

  @override
  TextSpan buildTextSpan({required BuildContext context, TextStyle? style, required bool withComposing}) {
    final bool composing = withComposing && value.isComposingRangeValid;
    if ((tabBlocks.isEmpty && chords.isEmpty) || composing || !_marksFit) {
      return super.buildTextSpan(context: context, style: style, withComposing: withComposing);
    }
    final TextScaler scaler = MediaQuery.textScalerOf(context);
    final TextStyle chordStyle = TextStyle(color: Theme.of(context).colorScheme.primary, fontWeight: FontWeight.w600);
    final List<_Mark> marks = <_Mark>[
      for (final TabBlock block in tabBlocks) (start: block.start, end: block.end, style: _tabStyle(style, block, scaler)),
      for (final LyricsChord chord in chords) (start: chord.start, end: chord.end, style: chordStyle),
    ]..sort((_Mark a, _Mark b) => a.start - b.start);
    final List<TextSpan> children = <TextSpan>[];
    int offset = 0;
    for (final _Mark mark in marks) {
      if (mark.start < offset) continue;
      if (mark.start > offset) children.add(TextSpan(text: text.substring(offset, mark.start)));
      children.add(TextSpan(text: text.substring(mark.start, mark.end), style: mark.style));
      offset = mark.end;
    }
    if (offset < text.length) children.add(TextSpan(text: text.substring(offset)));
    return TextSpan(style: style, children: children);
  }

  /// Whether the marks still match the text: while typing, the owner has not updated them yet.
  bool get _marksFit =>
      (tabBlocks.isEmpty || tabBlocks.last.end <= text.length) && (chords.isEmpty || chords.last.end <= text.length);

  /// Fixed-width style of [block]: the lyrics size, or smaller so its widest line fits [lineWidth].
  TextStyle _tabStyle(TextStyle? style, TabBlock block, TextScaler scaler) {
    final double baseSize = style?.fontSize ?? _defaultFontSize;
    final TextStyle monospace = (style ?? const TextStyle()).copyWith(
      fontFamily: _monospaceFamily,
      height: _tabLineHeight,
      // The theme spaces letters (Material 3 bodyLarge: 0.5), which would push a fitted tab past the edge.
      letterSpacing: 0,
      wordSpacing: 0,
    );
    final double? width = lineWidth;
    if (width == null || block.width == 0) return monospace;
    final double characterWidth = _measureCharacterWidth(monospace, scaler) * baseSize / _measureFontSize;
    final double fitted = baseSize * (width - _widthReserve) / (block.width * characterWidth);
    return monospace.copyWith(fontSize: math.max(_minTabFontSize, math.min(baseSize, fitted)));
  }

  /// Width of one character of [monospace] at [_measureFontSize], measured once per [scaler].
  double _measureCharacterWidth(TextStyle monospace, TextScaler scaler) {
    final double? measured = _characterWidth;
    if (measured != null && _measuredScaler == scaler) return measured;
    final TextPainter painter = TextPainter(
      text: TextSpan(
        text: _measureCharacter,
        style: monospace.copyWith(fontSize: _measureFontSize),
      ),
      textDirection: TextDirection.ltr,
      textScaler: scaler,
    )..layout();
    final double width = painter.width;
    painter.dispose();
    _characterWidth = width;
    _measuredScaler = scaler;
    return width;
  }
}

/// A part of the text drawn in its own style: a tab or a chord.
typedef _Mark = ({int start, int end, TextStyle style});
