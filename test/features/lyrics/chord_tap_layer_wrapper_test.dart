import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hitwave.cover/features/lyrics/presentation/wrappers/chord_tap_layer_wrapper.dart';

void main() {
  testWidgets('a tap on a range turns it over without focusing the field; a tap elsewhere edits', (
    WidgetTester tester,
  ) async {
    final TextEditingController controller = TextEditingController(text: 'Am girl to hold\nthe whole night long');
    final FocusNode focus = FocusNode();
    final GlobalKey fieldKey = GlobalKey();
    final List<int> tapped = <int>[];
    addTearDown(controller.dispose);
    addTearDown(focus.dispose);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Padding(
            padding: const EdgeInsets.all(40),
            child: ChordTapLayerWrapper(
              fieldKey: fieldKey,
              listenable: controller,
              rangesOf: () => <({int start, int end})>[(start: 0, end: 2)],
              onRangeTapped: tapped.add,
              child: TextField(key: fieldKey, controller: controller, focusNode: focus, maxLines: null),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final Rect field = tester.getRect(find.byType(TextField));
    await tester.tapAt(field.topLeft + const Offset(8, 10));
    await tester.pumpAndSettle();
    expect(tapped, <int>[0]);
    expect(focus.hasFocus, isFalse);

    await tester.tapAt(field.bottomLeft + const Offset(60, -10));
    await tester.pumpAndSettle();
    expect(tapped, <int>[0]);
    expect(focus.hasFocus, isTrue);
  });
}
