import 'package:flutter/rendering.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';
import 'package:watch_it/watch_it.dart';

/// Lays a tap target over every range of the text field's text ([rangesOf], e.g. the chords): a tap there calls
/// [onRangeTapped] with the index of the range and never reaches the field, so it does not focus it or open the
/// keyboard. Taps elsewhere go to the field as before.
///
/// The targets follow the text: they are measured again after every change of [listenable] and every layout.
final class ChordTapLayerWrapper extends WatchingStatefulWidget {
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
  const ChordTapLayerWrapper({
    required this.fieldKey,
    required this.listenable,
    required this.rangesOf,
    required this.onRangeTapped,
    required this.child,
    super.key,
  });

  @override
  State<ChordTapLayerWrapper> createState() => _ChordTapLayerWrapperState();
}

final class _ChordTapLayerWrapperState extends State<ChordTapLayerWrapper> {
  /// A little more than the letters, so a short chord (`A`) is easy to hit.
  static const double _slop = 4;

  /// Where the ranges are drawn now, with the index of each.
  final ValueNotifier<List<({int index, Rect rect})>> _targetsController =
      ValueNotifier<List<({int index, Rect rect})>>(const <({int index, Rect rect})>[]);
  bool _isMeasureScheduled = false;

  @override
  void initState() {
    super.initState();
    widget.listenable.addListener(_scheduleMeasure);
  }

  @override
  void didUpdateWidget(ChordTapLayerWrapper oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.listenable == widget.listenable) return;
    oldWidget.listenable.removeListener(_scheduleMeasure);
    widget.listenable.addListener(_scheduleMeasure);
  }

  @override
  void dispose() {
    widget.listenable.removeListener(_scheduleMeasure);
    _targetsController.dispose();
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
    _targetsController.value = targets;
  }

  bool _sameTargets(List<({int index, Rect rect})> targets) {
    final List<({int index, Rect rect})> shown = _targetsController.value;
    if (targets.length != shown.length) return false;
    for (int i = 0; i < targets.length; i++) {
      if (targets[i] != shown[i]) return false;
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
    final List<({int index, Rect rect})> targets = watch(_targetsController).value;
    return Stack(
      children: <Widget>[
        widget.child,
        for (final ({int index, Rect rect}) target in targets)
          Positioned.fromRect(
            rect: target.rect,
            child: _TapTargetWrapper(index: target.index, onTapped: widget.onRangeTapped),
          ),
      ],
    );
  }
}

/// A place over a range that takes the tap before the field does.
final class _TapTargetWrapper extends StatelessWidget {
  final int index;
  final ValueChanged<int> onTapped;

  const _TapTargetWrapper({required this.index, required this.onTapped});

  @override
  Widget build(BuildContext context) => GestureDetector(behavior: HitTestBehavior.opaque, onTap: _onTap);

  void _onTap() => onTapped(index);
}
