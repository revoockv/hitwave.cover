import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hitwave.cover/core/presentation/theme.dart';
import 'package:hitwave.cover/core/presentation/widgets/accent_action_button_widget.dart';
import 'package:hitwave.cover/core/presentation/widgets/surface_widget.dart';

void main() {
  for (final SurfaceStyle style in SurfaceStyle.values) {
    for (final Brightness brightness in Brightness.values) {
      test('$style $brightness keeps the accent and the surfaces', () {
        final ThemeData theme = AppTheme.build(style: style, brightness: brightness, accent: AppTheme.accentBlue);
        final SurfaceTheme surfaces = theme.extension<SurfaceTheme>()!;

        expect(theme.brightness, brightness);
        expect(theme.colorScheme.primary, AppTheme.accentBlue);
        expect(surfaces.style, style);
        expect(surfaces.blobs.isNotEmpty, style == SurfaceStyle.glass);
      });

      testWidgets('$style $brightness draws a panel', (WidgetTester tester) async {
        await tester.pumpWidget(
          MaterialApp(
            theme: AppTheme.build(style: style, brightness: brightness, accent: AppTheme.accentOrange),
            home: const Scaffold(body: SurfaceWidget(child: Text('panel'))),
          ),
        );

        expect(find.text('panel'), findsOneWidget);
        expect(find.byType(BackdropFilter), style == SurfaceStyle.glass ? findsOneWidget : findsNothing);
      });
    }
  }

  for (final SurfaceStyle style in SurfaceStyle.values) {
    testWidgets('the action button of $style shows its label and reacts to a tap', (WidgetTester tester) async {
      int taps = 0;
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.build(style: style, brightness: Brightness.dark, accent: AppTheme.accentBlue),
          home: Scaffold(
            floatingActionButton: AccentActionButtonWidget(icon: Icons.add, label: 'Add', onPressed: () => taps++),
          ),
        ),
      );

      await tester.tap(find.text('Add'));

      expect(taps, 1);
    });
  }
}
