import 'package:flutter/rendering.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';

/// Lays a tap target over every range of the text field's text ([rangesOf], e.g. the chords): a tap there calls
/// [onRangeTapped] with the index of the range and never reaches the field, so it does not focus it or open the
/// keyboard. Taps elsewhere go to the field as before.
///
/// The targets follow the text: they are measured again after every change of [listenable] and every layout.
final class ChordTapLayerWidget extends StatefulWidget {
  /// The key of the field whose text holds the ranges.
  final GlobalKey fieldKey;

  /// Changes when the text or its ranges change (the field's controller).
  final Listenable listenable;

  /// The ranges to tap, as offsets of the field's text.
  final List<({int start, int end})> Function() rangesOf;

  /// Called with the index of the tapped range in [rangesOf].
  final ValueChanged<int> onRangeTapped;

  /// The text field.
  final Widget child;

  /// Creates the layer.
  const ChordTapLayerWidget({
    required this.fieldKey,
    required this.listenable,
    required this.rangesOf,
    required this.onRangeTapped,
    required this.child,
    super.key,
  });

  @override
  State<ChordTapLayerWidget> createState() => _ChordTapLayerWidgetState();
}

final class _ChordTapLayerWidgetState extends State<ChordTapLayerWidget> {
  /// A little more than the letters, so a short chord (`A`) is easy to hit.
  static const double _slop = 4;

  List<({int index, Rect rect})> _targets = const <({int index, Rect rect})>[];
  bool _isMeasureScheduled = false;

  @override
  void initState() {
    super.initState();
    widget.listenable.addListener(_scheduleMeasure);
  }

  @override
  void didUpdateWidget(ChordTapLayerWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.listenable == widget.listenable) return;
    oldWidget.listenable.removeListener(_scheduleMeasure);
    widget.listenable.addListener(_scheduleMeasure);
  }

  @override
  void dispose() {
    widget.listenable.removeListener(_scheduleMeasure);
    super.dispose();
  }

  void _scheduleMeasure() {
    if (_isMeasureScheduled) return;
    _isMeasureScheduled = true;
    SchedulerBinding.instance
      ..addPostFrameCallback((Duration _) => _measure())
      ..ensureVisualUpdate();
  }

  /// Finds where the ranges are drawn now; rebuilds only when that changed.
  void _measure() {
    _isMeasureScheduled = false;
    if (!mounted) return;
    final RenderObject? layer = context.findRenderObject();
    final RenderObject? field = widget.fieldKey.currentContext?.findRenderObject();
    final RenderEditable? editable = field == null ? null : _editableIn(field);
    if (layer is! RenderBox || editable == null || !editable.hasSize) return;
    final int length = editable.text?.toPlainText().length ?? 0;
    final List<({int index, Rect rect})> targets = <({int index, Rect rect})>[];
    final List<({int start, int end})> ranges = widget.rangesOf();
    for (int index = 0; index < ranges.length; index++) {
      final ({int start, int end}) range = ranges[index];
      if (range.end > length) continue;
      for (final TextBox box in editable.getBoxesForSelection(
        TextSelection(baseOffset: range.start, extentOffset: range.end),
      )) {
        final Offset topLeft = editable.localToGlobal(Offset(box.left, box.top), ancestor: layer);
        targets.add((index: index, rect: (topLeft & Size(box.right - box.left, box.bottom - box.top)).inflate(_slop)));
      }
    }
    if (_sameTargets(targets)) return;
    setState(() => _targets = targets);
  }

  bool _sameTargets(List<({int index, Rect rect})> targets) {
    if (targets.length != _targets.length) return false;
    for (int i = 0; i < targets.length; i++) {
      if (targets[i] != _targets[i]) return false;
    }
    return true;
  }

  static RenderEditable? _editableIn(RenderObject node) {
    if (node is RenderEditable) return node;
    RenderEditable? found;
    node.visitChildren((RenderObject child) => found ??= _editableIn(child));
    return found;
  }

  @override
  Widget build(BuildContext context) {
    // A new layout (another width, another font size) moves the text: measure after it.
    _scheduleMeasure();
    return Stack(
      children: <Widget>[
        widget.child,
        for (final ({int index, Rect rect}) target in _targets)
          Positioned.fromRect(
            rect: target.rect,
            child: GestureDetector(behavior: HitTestBehavior.opaque, onTap: () => widget.onRangeTapped(target.index)),
          ),
      ],
    );
  }
}
