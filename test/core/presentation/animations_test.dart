import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hitwave.cover/core/presentation/theme.dart';
import 'package:hitwave.cover/core/presentation/widgets/fade_in_switcher_widget.dart';
import 'package:hitwave.cover/core/presentation/widgets/locale_fade_widget.dart';

/// Counts its builds; its state tells whether it was kept.
final class _Counter extends StatefulWidget {
  const _Counter();

  @override
  State<_Counter> createState() => _CounterState();
}

final class _CounterState extends State<_Counter> {
  int taps = 0;

  @override
  Widget build(BuildContext context) => Text('taps $taps');
}

void main() {
  test('a theme change blends the surfaces instead of swapping them halfway', () {
    final SurfaceTheme light = AppTheme.build(
      style: SurfaceStyle.glass,
      brightness: Brightness.light,
      accent: AppTheme.accentOrange,
    ).extension<SurfaceTheme>()!;
    final SurfaceTheme dark = AppTheme.build(
      style: SurfaceStyle.neumorphic,
      brightness: Brightness.dark,
      accent: AppTheme.accentAzure,
    ).extension<SurfaceTheme>()!;

    final SurfaceTheme middle = light.lerp(dark, 0.5);

    expect(middle.solid, Color.lerp(light.solid, dark.solid, 0.5));
    expect(middle.solid, isNot(anyOf(light.solid, dark.solid)));
    expect(middle.background, hasLength(3));
    expect(middle.blur, (light.blur + dark.blur) / 2);
    expect(light.lerp(dark, 0.4).style, SurfaceStyle.glass);
    expect(light.lerp(dark, 0.6).style, SurfaceStyle.neumorphic);
    expect(light.lerp(dark, 1).background.last, dark.background.last);
  });

  testWidgets('another language fades in and the page keeps its state', (WidgetTester tester) async {
    Widget app(Locale locale) => Localizations(
      locale: locale,
      delegates: const <LocalizationsDelegate<Object>>[DefaultWidgetsLocalizations.delegate],
      child: const Directionality(
        textDirection: TextDirection.ltr,
        child: LocaleFadeWidget(child: _Counter()),
      ),
    );
    await tester.pumpWidget(app(const Locale('en')));
    tester.state<_CounterState>(find.byType(_Counter)).taps = 3;
    FadeTransition fade() => tester.widget<FadeTransition>(find.byType(FadeTransition));
    expect(fade().opacity.value, 1);

    await tester.pumpWidget(app(const Locale('isv')));
    await tester.pump(const Duration(milliseconds: 50));
    expect(fade().opacity.value, lessThan(1));

    await tester.pumpAndSettle();
    expect(fade().opacity.value, 1);
    expect(tester.state<_CounterState>(find.byType(_Counter)).taps, 3);
  });

  testWidgets('another tab fades in and the old one is gone at once', (WidgetTester tester) async {
    Widget tab(String name) => Directionality(
      textDirection: TextDirection.ltr,
      child: FadeInSwitcherWidget(switchKey: name, child: Text(name)),
    );
    await tester.pumpWidget(tab('songs'));
    await tester.pumpAndSettle();

    await tester.pumpWidget(tab('tuner'));
    expect(find.text('songs'), findsNothing);
    expect(tester.widget<Opacity>(find.byType(Opacity)).opacity, lessThan(1));

    await tester.pumpAndSettle();
    expect(tester.widget<Opacity>(find.byType(Opacity)).opacity, 1);
  });
}
