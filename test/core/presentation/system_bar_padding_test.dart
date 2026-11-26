import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hitwave.cover/core/presentation/theme.dart';

void main() {
  Future<EdgeInsets> paddingUnder(WidgetTester tester, EdgeInsets systemPadding) async {
    late EdgeInsets padding;
    await tester.pumpWidget(
      MediaQuery(
        data: MediaQueryData(padding: systemPadding),
        child: Builder(
          builder: (BuildContext context) {
            padding = AppTheme.clearOfSystemBar(context, const EdgeInsets.all(AppTheme.spacingMedium));
            return const SizedBox();
          },
        ),
      ),
    );
    return padding;
  }

  testWidgets('the end of a scroll view stays above the Android navigation bar', (WidgetTester tester) async {
    final EdgeInsets padding = await paddingUnder(tester, const EdgeInsets.only(top: 24, bottom: 48));

    expect(padding.bottom, AppTheme.spacingMedium + 48);
    expect(padding.top, AppTheme.spacingMedium);
  });

  testWidgets('nothing is added where the bar took no space', (WidgetTester tester) async {
    expect((await paddingUnder(tester, EdgeInsets.zero)).bottom, AppTheme.spacingMedium);
  });
}
